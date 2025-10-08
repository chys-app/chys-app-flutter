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

  setUp(() async {
    Get.testMode = true;
    await StorageService.clearStorage();
    await Get.deleteAll(force: true);
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (tmpDir.existsSync()) {
      await tmpDir.delete(recursive: true);
    }
  });

  test('first launch triggers normal splash flow', () async {
    final controller = _TestSplashController();

    controller.onInit();

    expect(controller.hasShownSplash, isFalse);
    expect(controller.navigateCallCount, 1);
    expect(controller.lastSkipDelay, isFalse);

    controller.onClose();
  });

  test('subsequent launch skips splash animations entirely', () async {
    await StorageService.setStepDone(StorageService.splashShown);

    final controller = _TestSplashController();

    controller.onInit();
    await Future.delayed(Duration.zero);

    expect(controller.hasShownSplash, isTrue);
    expect(controller.navigateCallCount, 1);
    expect(controller.lastSkipDelay, isTrue);

    controller.onClose();
  });

  testWidgets('missing auth token navigates to login and marks splash as shown',
      (WidgetTester tester) async {
    final pages = [
      GetPage(
        name: AppRoutes.initial,
        page: () => const SizedBox.shrink(),
      ),
      GetPage(
        name: AppRoutes.login,
        page: () => const SizedBox.shrink(),
      ),
    ];

    late final TestGetObserver observer;

    await tester.pumpWidget(GetMaterialApp(
      navigatorKey: Get.key,
      initialRoute: AppRoutes.initial,
      getPages: pages,
      navigatorObservers: [observer = TestGetObserver()],
    ));
    await tester.pumpAndSettle();

    final previousTestMode = Get.testMode;
    Get.testMode = false;

    final controller = _SpySplashController();
    controller.onInit();

    await runZonedGuarded(() async {
      await tester.pumpAndSettle();
    }, (error, stackTrace) {
      if (error is MissingPluginException) {
        return;
      }
      fail('Unexpected error during splash navigation: $error');
    });

    expect(StorageService.isStepDone(StorageService.splashShown), isTrue);
    expect(observer.currentRoute, AppRoutes.login);
    expect(controller.lastNavigatedRoute, AppRoutes.login);

    controller.onClose();
    Get.testMode = previousTestMode;
  });
}

class _TestSplashController extends SplashController {
  int navigateCallCount = 0;
  bool? lastSkipDelay;

  @override
  Future<void> navigateToNextScreen({bool skipDelay = false}) async {
    navigateCallCount++;
    lastSkipDelay = skipDelay;
  }
}

class _SpySplashController extends SplashController {
  String? lastNavigatedRoute;

  @override
  Future<void> navigateToNextScreen({bool skipDelay = false}) async {
    await super.navigateToNextScreen(skipDelay: skipDelay);
    lastNavigatedRoute = Get.currentRoute;
  }

  @override
  Future<void> waitForInitialDelay({required bool skipDelay}) async {}
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
