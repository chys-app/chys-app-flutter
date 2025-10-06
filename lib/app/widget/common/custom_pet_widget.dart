import 'package:chys/app/modules/profile/controllers/profile_controller.dart';
import 'package:chys/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/const/app_colors.dart';
import '../../services/date_time_service.dart';
import '../shimmer/lottie_animation.dart';

class CustomPetWidget extends StatelessWidget {
  const CustomPetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profileData = Get.find<ProfileController>().userPet.value;
      if (profileData == null) {
        return const Center(
          child: CustomLottieAnimation(),
        );
      }

      return Stack(
        children: [
          InkWell(
            onTap: () {
              Get.toNamed(AppRoutes.homeDetail, arguments: profileData.id);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.blue.withOpacity(0.08),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image on Top
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      profileData.profilePic ?? '',
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset('assets/images/fallback_pet.png'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Name
                  Row(
                    children: [
                      const Icon(Icons.pets, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        profileData.name ?? "Unknown",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[900],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Age
                  Row(
                    children: [
                      const Icon(Icons.cake, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        "Age: ${DateTimeService.calculateAge(profileData.dateOfBirth!)}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Breed
                  Row(
                    children: [
                      const Icon(Icons.category, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text(
                        "Breed: ${profileData.breed ?? "Unknown"}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Gender
                  Row(
                    children: [
                      const Icon(Icons.wc, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text(
                        "Sex: ${profileData.sex == "Male" ? "Male ♂" : "Female ♀"}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Obx(() {
            final profileController = Get.find<ProfileController>();
            final hasPet = profileController.userPet.value != null;
            
            return !profileController.isCurrentUser.value || !hasPet
                ? const SizedBox.shrink()
                : Positioned(
                    right: 5,
                    top: 5,
                    child: IconButton(
                        onPressed: () {
                          Get.toNamed(AppRoutes.petEditSelectionFlow);
                        },
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.black,
                        )));
          }),
        ],
      );
    });
  }
}
