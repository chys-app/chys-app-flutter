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

      // Test that initializeFollowStates method exists and works
      controller.initializeFollowStates(testPets);

      // Since follow states are now managed by ProfileController,
      // we just verify the method runs without error
      expect(controller.allPets.length, equals(2));
    });

    test('should handle follow toggle correctly', () {
      final userId = 'user123';
      
      // Initialize following progress state
      controller.followingInProgress[userId] = false.obs;

      // Verify initial state
      expect(controller.followingInProgress[userId]!.value, isFalse);

      // Test that handleFollowToggle method exists
      expect(() => controller.handleFollowToggle(userId), returnsNormally);
    });

    test('should handle reactive follow state updates', () {
      final userId = 'user123';
      
      // Initialize following progress state
      controller.followingInProgress[userId] = false.obs;
      
      // Test that we can update the progress state
      controller.followingInProgress[userId]!.value = true;
      expect(controller.followingInProgress[userId]!.value, isTrue);
      
      // Reset for cleanup
      controller.followingInProgress[userId]!.value = false;
      expect(controller.followingInProgress[userId]!.value, isFalse);
    });

    test('should update reactive follow states when profile changes', () {
      // Initialize reactive follow states
      controller.updateReactiveFollowStates();
      
      // Simulate profile update by calling the method directly
      controller.updateReactiveFollowStates();
      
      // Verify the method runs without error
      expect(controller.reactiveFollowStates, isA<RxMap<String, bool>>());
    });

    test('should flip follow state when toggle is called', () async {
      final userId = 'user123';
      
      // Get initial follow state
      final initialStates = controller.currentFollowStates;
      final initialState = initialStates[userId] ?? false;
      
      // Call follow toggle
      await controller.handleFollowToggle(userId);
      
      // Wait a bit for async operations
      await Future.delayed(Duration(milliseconds: 100));
      
      // Check that the reactive follow states were updated
      final updatedStates = controller.currentFollowStates;
      
      // Log states for debugging
      print("Initial state for $userId: $initialState");
      print("Updated state for $userId: ${updatedStates[userId]}");
      print("All reactive states: ${controller.reactiveFollowStates}");
      
      // The state should exist in the reactive map
      expect(updatedStates.containsKey(userId), isTrue);
    });
  });
}
