import 'package:get/get.dart';
import '../../../core/controllers/loading_controller.dart';
import '../controllers/chat_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../user_management/controllers/user_management_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize ProfileController first since ChatController depends on it
    Get.lazyPut<ProfileController>(
      () => ProfileController(),
    );

    // Initialize LoadingController for loading states
    Get.lazyPut<LoadingController>(
      () => LoadingController(),
    );

    // Initialize UserManagementController for user actions
    Get.lazyPut<UserManagementController>(
      () => UserManagementController(),
    );

    // Initialize ChatController
    Get.lazyPut<ChatController>(
      () => ChatController(),
    );
  }
}
