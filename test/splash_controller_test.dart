import 'dart:async';
import 'dart:io';

import 'package:chys/app/modules/splash/controller/splash_controller.dart';
import 'package:chys/app/routes/app_routes.dart';
import 'package:chys/app/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory tmpDir;

  setUpAll(() async {
    tmpDir = await Directory.systemTemp.createTemp('splash_controller_test');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      switch (methodCall.method) {
        case 'getTemporaryDirectory':
        case 'getApplicationDocumentsDirectory':
        case 'getApplicationSupportDirectory':
        case 'getLibraryDirectory':
        case 'getDownloadsDirectory':
        case 'getExternalStorageDirectory':
          return tmpDir.path;
        case 'getExternalStorageDirectories':
        case 'getExternalCacheDirectories':
          return <String>[tmpDir.path];
        default:
          return null;
      }
    });

    await GetStorage.init();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (tmpDir.existsSync()) {
      await tmpDir.delete(recursive: true);
    }
  });

  setUp(() async {
    Get.testMode = true;
    await StorageService.clearStorage();
    await Get.deleteAll(force: true);
  });

  tearDown(() async {
    await Get.deleteAll(force: true);
    await StorageService.clearStorage();
  });

  test('subsequent launch skips splash delay', () async {
    await StorageService.setStepDone(StorageService.splashShown);

    final controller = _SpySplashController();
    controller.onInit();

    // Allow the microtask scheduled in onInit to run.
    await Future<void>.delayed(Duration.zero);

    expect(controller.hasShownSplash, isTrue);
    expect(controller.navigateCallCount, 1);
    expect(controller.lastSkipDelay, isTrue);

    controller.onClose();
  });

  testWidgets('first launch navigates to login and marks splash as shown',
      (WidgetTester tester) async {
    await StorageService.clearStorage();

    final observer = TestGetObserver();

    Get.testMode = false;
    await tester.pumpWidget(GetMaterialApp(
      navigatorKey: Get.key,
      initialRoute: AppRoutes.initial,
      getPages: [
        GetPage(
          name: AppRoutes.initial,
          page: () => const SizedBox.shrink(),
        ),
        GetPage(
          name: AppRoutes.login,
          page: () => const SizedBox.shrink(),
        ),
        GetPage(
          name: AppRoutes.home,
          page: () => const SizedBox.shrink(),
        ),
      ],
      navigatorObservers: [observer],
    ));
    await tester.pumpAndSettle();

    final controller = _SpySplashController();
    controller.onInit();

    await tester.pumpAndSettle();

    expect(StorageService.isStepDone(StorageService.splashShown), isTrue);
    expect(observer.currentRoute, AppRoutes.login);
    expect(controller.lastRoute, AppRoutes.login);

    controller.onClose();
    Get.testMode = true;
  });

  testWidgets('existing token navigates to home', (WidgetTester tester) async {
    await StorageService.clearStorage();
    await StorageService.saveToken('token');

    final observer = TestGetObserver();

    Get.testMode = false;
    await tester.pumpWidget(GetMaterialApp(
      navigatorKey: Get.key,
      initialRoute: AppRoutes.initial,
      getPages: [
        GetPage(
          name: AppRoutes.initial,
          page: () => const SizedBox.shrink(),
        ),
        GetPage(
          name: AppRoutes.login,
          page: () => const SizedBox.shrink(),
        ),
        GetPage(
          name: AppRoutes.home,
          page: () => const SizedBox.shrink(),
        ),
      ],
      navigatorObservers: [observer],
    ));
    await tester.pumpAndSettle();

    final controller = _SpySplashController();
    controller.onInit();

    await tester.pumpAndSettle();

    expect(StorageService.isStepDone(StorageService.splashShown), isTrue);
    expect(observer.currentRoute, AppRoutes.home);
    expect(controller.lastRoute, AppRoutes.home);

    controller.onClose();
    Get.testMode = true;
  });
}

class _SpySplashController extends SplashController {
  int navigateCallCount = 0;
  bool? lastSkipDelay;
  String? lastRoute;

  @override
  Future<void> waitForInitialDelay({required bool skipDelay}) async {
    lastSkipDelay = skipDelay;
    // No delay during tests.
  }

  @override
  Future<void> navigateToNextScreen({bool skipDelay = false}) async {
    navigateCallCount++;
    await super.navigateToNextScreen(skipDelay: skipDelay);
    lastRoute = Get.currentRoute;
  }
}

class TestGetObserver extends GetObserver {
  String? currentRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    currentRoute = route.settings.name;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    currentRoute = newRoute?.settings.name;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    currentRoute = previousRoute?.settings.name;
  }
}
