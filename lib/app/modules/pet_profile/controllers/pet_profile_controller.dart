import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class PetProfileController extends GetxController {
  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final bioController = TextEditingController();
  final dobController = TextEditingController();
  
  final selectedSex = 'Male'.obs;
  final isSpayedNeutered = false.obs;
  final petPhoto = Rx<File?>(null);

  final _imagePicker = ImagePicker();

  // List of dog breeds
  final List<String> breeds = [
    'Labrador Retriever',
    'German Shepherd',
    'Golden Retriever',
    'French Bulldog',
    'Bulldog',
    'Poodle',
    'Beagle',
    'Rottweiler',
    'Dachshund',
    'Yorkshire Terrier',
    'Boxer',
    'Chihuahua',
    // Add more breeds as needed
  ];

  Future<void> pickPetPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        petPhoto.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      dobController.text = '${picked.day.toString().padLeft(2, '0')} / '
          '${picked.month.toString().padLeft(2, '0')} / '
          '${picked.year}';
    }
  }

  void savePetProfile() {
    // Validate required fields
    if (nameController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter your pet\'s name');
      return;
    }
    if (breedController.text.isEmpty) {
      Get.snackbar('Error', 'Please select your pet\'s breed');
      return;
    }
    if (dobController.text.isEmpty) {
      Get.snackbar('Error', 'Please select your pet\'s date of birth');
      return;
    }
    if (petPhoto.value == null) {
      Get.snackbar('Error', 'Please add a photo of your pet');
      return;
    }

    // Save pet profile data
    final petData = {
      'name': nameController.text,
      'breed': breedController.text,
      'sex': selectedSex.value,
      'dateOfBirth': dobController.text,
      'isSpayedNeutered': isSpayedNeutered.value,
      'bio': bioController.text,
      'photoPath': petPhoto.value?.path,
    };

    // TODO: Save pet data to your storage/backend
    
    // Navigate to next screen
    Get.toNamed('/next-screen'); // Replace with your actual route
  }

  void goBack() {
    Get.back();
  }

  @override
  void onClose() {
    nameController.dispose();
    breedController.dispose();
    bioController.dispose();
    dobController.dispose();
    super.onClose();
  }
} 