import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/const/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widget/app_button.dart';
import '../../signup/widgets/custom_text_field.dart';
import '../controllers/pet_edit_controller.dart';
import '../../../core/const/app_image.dart';
import 'package:flutter_dotted/flutter_dotted.dart';
import '../../../routes/app_routes.dart';

class EditAppearanceView extends GetView<PetEditController> {
  const EditAppearanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const AppText(
                  text: 'Appearance',
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AppText(
                      text: 'Photos',
                      color: AppColors.purple,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    Obx(() => AppText(
                          text: '${controller.getCurrentPhotoCount()}/5',
                          color: AppColors.purple,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Upload Progress Card
                Obx(() => controller.isUploading.value
                    ? Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.cloud_upload_outlined,
                                  color: AppColors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    controller.uploadStatus.value,
                                    style: const TextStyle(
                                      color: AppColors.blue,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: controller.uploadProgress.value / 100,
                                    backgroundColor: Colors.blue.shade100,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${controller.uploadProgress.value.toInt()}%',
                                  style: const TextStyle(
                                    color: AppColors.blue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${controller.uploadedFiles.value}/${controller.totalFiles.value} files uploaded',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink()),
                
                Obx(() {
                  final networkPhotos = controller.petData.value?.photos ?? [];
                  final availableNetworkPhotos = networkPhotos
                      .where((url) =>
                          url.isNotEmpty &&
                          url != "[]" &&
                          !controller.removedNetworkImages.contains(url))
                      .toList();
                  final hasAny = availableNetworkPhotos.isNotEmpty ||
                      controller.photos.isNotEmpty;

                  if (!hasAny) {
                    return GestureDetector(
                      onTap: () => controller.pickAdditionalPhotos(),
                      child: FlutterDotted(
                        color: AppColors.blue,
                        gap: 4,
                        strokeWidth: 1.5,
                        child: Container(
                          width: double.infinity,
                          height: 160,
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                AppImages.upload,
                                height: 60,
                                color: AppColors.blue,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload up to 5 Photos',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: AppColors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final total =
                      availableNetworkPhotos.length + controller.photos.length;
                  return FlutterDotted(
                    color: AppColors.blue,
                    gap: 4,
                    strokeWidth: 1.5,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: total,
                            itemBuilder: (context, index) {
                              if (index < availableNetworkPhotos.length) {
                                final imageUrl = availableNetworkPhotos[index];
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () =>
                                            controller.removeImage(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }
                              final localIndex =
                                  index - availableNetworkPhotos.length;
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      controller.photos[localIndex],
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () =>
                                          controller.removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          if (controller.canAddMorePhotos()) ...[
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () =>
                                  controller.pickAdditionalPhotos(),
                              icon: const Icon(
                                  Icons.add_photo_alternate_outlined),
                              label: AppText(
                                text:
                                    'Add More Photos (${controller.getRemainingPhotoSlots()} remaining)',
                                fontSize: 16,
                                color: AppColors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const AppText(
                                text: 'Maximum 5 photos reached',
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                const AppText(
                  text: 'Pet Color',
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  hint: 'e.g, Brown or white',
                  controller: controller.petColorController,
                ),
                const SizedBox(height: 24),
                const AppText(
                  text: 'Breed',
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: controller.breedController,
                  hint: 'Enter breed(s), e.g., Labrador, Poodle...',
                  maxLines: null,
                ),
                const SizedBox(height: 24),
                const AppText(
                  text: 'Size',
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  isDropdown: true,
                  selectedValue: controller.selectedSize.value.isNotEmpty
                      ? controller.selectedSize.value
                      : null,
                  items: controller.sizeOptions,
                  onDropdownChanged: (value) {
                    if (value != null) controller.selectSize(value);
                  },
                ),
                const SizedBox(height: 24),
                const AppText(
                  text: 'Weight kg',
                  color: AppColors.purple,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  hint: 'Weight in kg',
                  controller: controller.weightController,
                  keyboardType: TextInputType.number,
                  onChanged: controller.onWeightChanged,
                ),
                const SizedBox(height: 8),
                Obx(() => controller.weightInLbs.value.isNotEmpty
                    ? AppText(
                        text: 'Weight in lbs: ${controller.weightInLbs.value}',
                        color: AppColors.purple,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      )
                    : const SizedBox.shrink()),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Appbutton(
                        onPressed: () => controller.goBack(),
                        label: 'Back',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Appbutton(
                        backgroundColor: AppColors.blue,
                        borderWidth: 0,
                        label: 'Next',
                        onPressed: () =>
                            Get.toNamed(AppRoutes.petEditIdentificationFlow),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
