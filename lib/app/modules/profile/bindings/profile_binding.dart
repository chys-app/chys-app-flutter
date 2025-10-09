import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../user_management/controllers/user_management_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(
      () => ProfileController(),
    );
    
    // Initialize UserManagementController for user actions
    Get.lazyPut<UserManagementController>(
      () => UserManagementController(),
    );
  }
} 