import 'package:chys/app/modules/map/controllers/map_controller.dart';
import 'package:chys/app/modules/profile/controllers/profile_controller.dart';
import 'package:get/get.dart';

import '../../../data/controllers/floating_button_controller.dart';
import '../controllers/product_controller.dart';

class ProductBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductController>(
      () => ProductController(),
    );
    Get.lazyPut<ProfileController>(
      () => ProfileController(),
    );
    Get.lazyPut<MapController>(
      () => MapController(),
    );
    Get.lazyPut<FloatingButtonController>(
      () => FloatingButtonController(),
    );
    
  }
}
