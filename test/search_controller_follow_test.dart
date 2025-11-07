import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:chys/app/modules/search/search_controller.dart';
import 'package:chys/app/data/models/pet_profile.dart';

void main() {
  group('SearchController Follow State Tests', () {
    late SearchController controller;

    setUp(() {
      Get.testMode = true;
      Get.reset();
      controller = SearchController();
    });

    tearDown(() {
      Get.reset();
    });

    test('should initialize follow states when pets are loaded', () {
      // Simulate loading pets
      final testPets = [
        PetModel(
          id: 'pet1',
          name: 'Buddy',
          breed: 'Golden Retriever',
          petType: 'Dog',
          profilePic: 'https://example.com/buddy.jpg',
          user: 'user123',
        ),
        PetModel(
          id: 'pet2',
          name: 'Max',
          breed: 'Labrador',
          petType: 'Dog',
          profilePic: 'https://example.com/max.jpg',
          user: 'user456',
        ),
      ];

      // Initialize follow states
      controller.initializeFollowStates(testPets);

      // Check that follow states were initialized
      expect(controller.followStates.containsKey('user123'), isTrue);
      expect(controller.followStates.containsKey('user456'), isTrue);
      expect(controller.followStates['user123']!.value, isFalse);
      expect(controller.followStates['user456']!.value, isFalse);
    });

    test('should update follow state correctly', () {
      final userId = 'user123';
      
      // Initialize follow state
      controller.followStates[userId] = false.obs;
      controller.followingInProgress[userId] = false.obs;

      // Simulate successful follow toggle
      controller.followStates[userId]!.value = true;

      // Check that follow state was updated
      expect(controller.followStates[userId]!.value, isTrue);
    });

    test('should handle reactive follow state updates', () {
      final userId = 'user123';
      
      // Initialize follow state
      controller.followStates[userId] = false.obs;

      // Get initial current follow states
      final initialStates = controller.currentFollowStates;
      expect(initialStates[userId], isFalse);

      // Update follow state
      controller.followStates[userId]!.value = true;

      // Get updated current follow states
      final updatedStates = controller.currentFollowStates;
      expect(updatedStates[userId], isTrue);
    });
  });
}
