import 'package:get/get.dart';
import '../controllers/pet_edit_controller.dart';

class PetEditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PetEditController>(() => PetEditController());
  }
} 