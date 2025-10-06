import 'package:get/get.dart';

class FloatingButtonController extends GetxController {
  RxBool hideOtherImage = true.obs;

  RxString selectedFeature = ''.obs;

  void selectFeature(String feature) {
    if (selectedFeature.value == feature) {
      selectedFeature.value = '';
      Get.find<FloatingButtonController>().hideOtherImage.value = true;
    } else {
      selectedFeature.value = feature;
      Get.find<FloatingButtonController>().hideOtherImage.value = false;
    }
  }
}
