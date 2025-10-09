import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../user_management/controllers/user_management_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(
      () => SettingsController(),
    );
    
    // Initialize UserManagementController for user actions
    Get.lazyPut<UserManagementController>(
      () => UserManagementController(),
    );
  }
} 