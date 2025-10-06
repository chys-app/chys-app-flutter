import 'package:chys/app/modules/splash/controller/splash_controller.dart';
import 'package:get/get.dart';

import '../../modules/map/controllers/map_controller.dart';

class ControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MapController>(() => MapController(), fenix: true);
    Get.put(SplashController(), permanent: true);
  }
}
