import 'package:chys/app/core/const/app_text.dart';
import 'package:chys/app/modules/signup/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widget/app_button.dart';
import '../../signup/controller/signup_controller.dart';

class DogBreedsView extends GetView<SignupController> {
  const DogBreedsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => controller.goBack(),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              const SizedBox(height: 24),

              // Title
              const AppText(
                text: 'Enter dog races',
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
              const SizedBox(height: 32),

              // Subtitle
              const AppText(
                text:
                    'This will help us find you neighbor dogs of your interest',
                fontSize: 14,
                color: AppColors.purple,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: controller.breedTextController,
                hint: "Enter dog breed(s), e.g., Labrador, Poodle...",
                maxLines: null, // Optional: allows multiline
              ),
              const SizedBox(height: 32),

              // // Dog Breeds Grid
              // Expanded(
              //   child: SingleChildScrollView(
              //     child: Wrap(
              //       spacing: 8,
              //       runSpacing: 12,
              //       children: [
              //         _buildBreedChip('Affenpinscher'),
              //         _buildBreedChip('Afghan Hound'),
              //         _buildBreedChip('Airedale Terrier'),
              //         _buildBreedChip('Akita'),
              //         _buildBreedChip('Anatolian Shepherd'),
              //         _buildBreedChip('Estrela Mountain'),
              //         _buildBreedChip('Australian Cattle'),
              //         _buildBreedChip('Australian Kelpie'),
              //         _buildBreedChip('Australian Silky Terrier'),
              //         _buildBreedChip('Basenji'),
              //         // Add more breeds as needed
              //       ],
              //     ),
              //   ),
              // ),

              // Navigation Buttons

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
                      onPressed: () => controller.savePetProfile(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
