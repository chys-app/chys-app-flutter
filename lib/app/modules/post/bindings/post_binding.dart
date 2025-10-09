import 'package:chys/app/modules/map/controllers/map_controller.dart';
import 'package:chys/app/modules/profile/controllers/profile_controller.dart';
import 'package:get/get.dart';

import '../../../data/controllers/floating_button_controller.dart';
import '../../adored_posts/controller/controller.dart';
import '../controllers/post_controller.dart';

class PostBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostController>(
      () => PostController(),
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
    // Add AddoredPostsController with home tag to match the home view
    Get.lazyPut<AddoredPostsController>(
      () => AddoredPostsController(),
      tag: 'home',
    );
  }
}
