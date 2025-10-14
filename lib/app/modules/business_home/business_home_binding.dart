import 'package:get/get.dart';
import 'business_home_controller.dart';

class BusinessHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BusinessHomeController>(() => BusinessHomeController());
  }
}
