import 'package:chys/app/modules/donate/controller/donate_controller.dart';
import 'package:get/get.dart';

class DonateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DonateController>(
      () => DonateController(),
    );
  }
}
