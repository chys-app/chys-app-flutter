import 'package:chys/app/core/binding/controller_binding.dart';
import 'package:chys/app/data/controllers/location_controller.dart';
import 'package:chys/app/services/notification_service.dart';
import 'package:chys/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chys/app/core/const/app_secrets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/core/controllers/loading_controller.dart';
import 'app/core/widget/loading_overlay.dart';
import 'app/modules/profile/controllers/profile_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/routes/route_observer.dart';
import 'app/services/custom_Api.dart';
import 'app/services/dynamic_link_service.dart';
import 'app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await GetStorage.init();
  CustomApiService();
  Get.put(ProfileController());
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Stripe.publishableKey = AppSecrets.publishableKey;
  // Stripe.urlScheme = 'flutterstripe';
  // Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
  Stripe.merchantIdentifier = 'test';
  await Stripe.instance.applySettings();
  final dynamicLinkService = FirebaseDynamicLinkService();
  await dynamicLinkService.initDynamicLinks();

  // Inject as singleton
  Get.put<FirebaseDynamicLinkService>(dynamicLinkService, permanent: true);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

@pragma('vm:entry-point') // Required for iOS/Android
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  NotificationUtil().showNotification(message);

  // Optional: handle data for silent notifications or local triggers
}

final AppRouteObserver appRouteObserver = AppRouteObserver();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(LocationController(), permanent: true);
    final loadingController = Get.put(LoadingController(), permanent: true);
    return GetMaterialApp(
      title: 'Pet Profile App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            Obx(
              () => LoadingOverlay(
                isLoading: loadingController.isLoading.value,
              ),
            ),
          ],
        );
      },
      initialBinding: ControllerBinding(),
      navigatorObservers: [appRouteObserver],
    );
  }
}
