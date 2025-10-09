import 'package:get/get.dart';

class PetDataController extends GetxController {
  final _petType = ''.obs;

  String get petType => _petType.value;
  
  void setPetType(String type) {
    _petType.value = type;
  }
  
  // Add more pet-related data management methods as needed
} 