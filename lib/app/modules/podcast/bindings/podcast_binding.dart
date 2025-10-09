import 'package:chys/app/modules/podcast/controllers/create_podcast_controller.dart';
import 'package:get/get.dart';

import '../controllers/podcast_controller.dart';

class PodcastBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PodcastController>(
      () => PodcastController(),
    );
    Get.lazyPut<CreatePodCastController>(
      () => CreatePodCastController(),
    );
  }
}
