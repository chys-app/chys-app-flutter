import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:chys/app/data/models/pet_profile.dart';
import 'package:chys/app/modules/search/widgets/search_widget.dart';

void main() {
  group('SearchWidget Tests', () {
    late List<PetModel> testPets;
    late Map<String, bool> testFollowStates;
    late Map<String, bool> testFollowingInProgress;

    setUp(() {
      testPets = [
        PetModel(
          id: 'pet1',
          name: 'Happy',
          breed: 'Golden Retriever',
          petType: 'Dog',
          profilePic: 'https://example.com/happy.jpg',
          photos: ['https://example.com/happy.jpg'],
          user: 'user123',
        ),
        PetModel(
          id: 'pet2',
          name: 'Luna',
          breed: 'Siamese',
          petType: 'Cat',
          profilePic: 'https://example.com/luna.jpg',
          photos: ['https://example.com/luna.jpg'],
          user: 'user456',
        ),
      ];

      testFollowStates = {
        'user123': true,  // Following
        'user456': false, // Not following
      };

      testFollowingInProgress = {
        'user123': false,
        'user456': false,
      };
    });

    testWidgets('should display pet grid correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SearchWidget(
              allPets: testPets,
              filteredPets: testPets,
              isLoadingPets: false,
              searchQuery: '',
              onSearchChanged: (query) {},
              onClearSearch: () {},
              onFollowToggle: (userId) {},
              onPetTap: (petId) {},
              followStates: testFollowStates,
              followingInProgress: testFollowingInProgress,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify pet names are displayed (there might be multiple "Happy" text widgets)
      expect(find.text('Happy'), findsAtLeastNWidgets(1));
      expect(find.text('Luna'), findsAtLeastNWidgets(1));

      // Verify follow buttons exist
      expect(find.byKey(Key('follow_button_user123')), findsOneWidget);
      expect(find.byKey(Key('follow_button_user456')), findsOneWidget);
    });

    testWidgets('should handle follow button tap', (WidgetTester tester) async {
      bool followTapped = false;
      String tappedUserId = '';

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SearchWidget(
              allPets: testPets,
              filteredPets: testPets,
              isLoadingPets: false,
              searchQuery: '',
              onSearchChanged: (query) {},
              onClearSearch: () {},
              onFollowToggle: (userId) {
                followTapped = true;
                tappedUserId = userId;
              },
              onPetTap: (petId) {},
              followStates: testFollowStates,
              followingInProgress: testFollowingInProgress,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Happy's follow button
      await tester.tap(find.byKey(Key('follow_button_user123')));
      await tester.pumpAndSettle();

      expect(followTapped, isTrue);
      expect(tappedUserId, equals('user123'));
    });

    testWidgets('should show loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SearchWidget(
              allPets: [],
              filteredPets: [],
              isLoadingPets: true,
              searchQuery: '',
              onSearchChanged: (query) {},
              onClearSearch: () {},
              onFollowToggle: (userId) {},
              onPetTap: (petId) {},
              followStates: {},
              followingInProgress: {},
            ),
          ),
        ),
      );

      await tester.pump(); // Just pump once, don't wait for settle

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show empty state when no pets', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SearchWidget(
              allPets: [],
              filteredPets: [],
              isLoadingPets: false,
              searchQuery: '',
              onSearchChanged: (query) {},
              onClearSearch: () {},
              onFollowToggle: (userId) {},
              onPetTap: (petId) {},
              followStates: {},
              followingInProgress: {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state message (not searching, so "No pets yet")
      expect(find.text('No pets yet'), findsOneWidget);
    });

    testWidgets('should handle search functionality', (WidgetTester tester) async {
      String searchQuery = '';

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SearchWidget(
              allPets: testPets,
              filteredPets: [testPets[0]], // Only Happy
              isLoadingPets: false,
              searchQuery: searchQuery,
              onSearchChanged: (query) {
                searchQuery = query;
              },
              onClearSearch: () {
                searchQuery = '';
              },
              onFollowToggle: (userId) {},
              onPetTap: (petId) {},
              followStates: testFollowStates,
              followingInProgress: testFollowingInProgress,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Happy');
      await tester.pumpAndSettle();

      expect(searchQuery, equals('Happy'));
    });

    testWidgets('should filter out current user\'s pets', (WidgetTester tester) async {
      // Test data includes a pet that belongs to current user
      final allPetsIncludingCurrentUser = [
        PetModel(
          id: 'pet1',
          name: 'Happy',
          breed: 'Golden Retriever',
          petType: 'Dog',
          profilePic: 'https://example.com/happy.jpg',
          photos: ['https://example.com/happy.jpg'],
          user: 'user123', // Different user
        ),
        PetModel(
          id: 'pet2',
          name: 'My Own Pet',
          breed: 'Labrador',
          petType: 'Dog',
          profilePic: 'https://example.com/mypet.jpg',
          photos: ['https://example.com/mypet.jpg'],
          user: 'current_user_456', // Current user's pet - should be filtered out
        ),
      ];

      // Simulate filtered list (excludes current user's pets)
      final filteredPetsOnly = [
        allPetsIncludingCurrentUser[0] // Only Happy
      ];

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SearchWidget(
              allPets: allPetsIncludingCurrentUser, // All pets including current user's
              filteredPets: filteredPetsOnly, // Filtered list excludes current user's pets
              isLoadingPets: false,
              searchQuery: '',
              onSearchChanged: (query) {},
              onClearSearch: () {},
              onFollowToggle: (userId) {},
              onPetTap: (petId) {},
              followStates: {
                'user123': false,
                'current_user_456': false, // This shouldn't appear in UI
              },
              followingInProgress: {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should only show Happy (not current user's pet) in the filtered results
      expect(find.text('Happy'), findsAtLeastNWidgets(1));
      expect(find.text('My Own Pet'), findsNothing);
      
      // Should only have follow button for Happy (not current user's pet)
      expect(find.byKey(Key('follow_button_user123')), findsOneWidget);
      expect(find.byKey(Key('follow_button_current_user_456')), findsNothing);
    });
  });
}
