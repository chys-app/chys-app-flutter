import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chys/app/data/models/pet_profile.dart';
import 'package:chys/app/modules/search/widgets/search_widget.dart';

void main() {
  group('SearchWidget Follow Button Tests', () {
    late List<PetModel> testPets;
    late String testUserId;
    late String testPetId;
    late bool followToggleCalled;
    late String? followToggleUserId;

    setUp(() {
      testUserId = 'user123';
      testPetId = 'pet456';
      followToggleCalled = false;
      followToggleUserId = null;

      testPets = [
        PetModel(
          id: testPetId,
          name: 'Buddy',
          breed: 'Golden Retriever',
          petType: 'Dog',
          profilePic: 'https://example.com/buddy.jpg',
          user: testUserId,
        ),
        PetModel(
          id: 'pet789',
          name: 'Max',
          breed: 'Labrador',
          petType: 'Dog',
          profilePic: 'https://example.com/max.jpg',
          user: 'user456',
        ),
      ];
    });

    Widget createTestWidget({
      Map<String, bool> followStates = const {},
      Map<String, bool> followingInProgress = const {},
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SearchWidget(
            allPets: testPets,
            filteredPets: testPets,
            isLoadingPets: false,
            searchQuery: '',
            onSearchChanged: (_) {},
            onClearSearch: () {},
            onFollowToggle: (userId) {
              followToggleCalled = true;
              followToggleUserId = userId;
            },
            onPetTap: (_) {},
            followStates: followStates,
            followingInProgress: followingInProgress,
          ),
        ),
      );
    }

    testWidgets('should display follow buttons on pet tiles', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find the follow buttons using their specific keys
      expect(find.byKey(Key('follow_button_user123')), findsOneWidget);
      expect(find.byKey(Key('follow_button_user456')), findsOneWidget);
    });

    testWidgets('should call onFollowToggle when follow button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        followStates: {testUserId: false},
      ));

      // Find and tap the specific follow button by key
      final followButton = find.byKey(Key('follow_button_$testUserId'));
      expect(followButton, findsOneWidget);
      
      await tester.tap(followButton);
      await tester.pump();

      expect(followToggleCalled, isTrue);
      expect(followToggleUserId, equals(testUserId));
    });

    testWidgets('should show loading indicator when follow is in progress', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        followStates: {testUserId: false},
        followingInProgress: {testUserId: true},
      ));

      // Should show CircularProgressIndicator when in progress
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('should not show follow button for pet without user', (WidgetTester tester) async {
      final petsWithoutUser = [
        PetModel(
          id: 'pet999',
          name: 'Ghost',
          breed: 'Mystery',
          petType: 'Unknown',
          profilePic: 'https://example.com/ghost.jpg',
          user: null, // No user ID
        ),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SearchWidget(
            allPets: petsWithoutUser,
            filteredPets: petsWithoutUser,
            isLoadingPets: false,
            searchQuery: '',
            onSearchChanged: (_) {},
            onClearSearch: () {},
            onFollowToggle: (userId) {
              followToggleCalled = true;
              followToggleUserId = userId;
            },
            onPetTap: (_) {},
            followStates: {},
            followingInProgress: {},
          ),
        ),
      ));

      // Should not show any follow buttons since pet has no user
      expect(find.byKey(Key('follow_button_user123')), findsNothing);
      expect(find.byKey(Key('follow_button_user456')), findsNothing);
    });

    testWidgets('should handle multiple pets with different follow states', (WidgetTester tester) async {
      final secondUserId = 'user456';
      
      await tester.pumpWidget(createTestWidget(
        followStates: {
          testUserId: true,  // First pet is followed
          secondUserId: false,  // Second pet is not followed
        },
      ));

      // Should have follow buttons for both pets regardless of state
      expect(find.byKey(Key('follow_button_$testUserId')), findsOneWidget);
      expect(find.byKey(Key('follow_button_$secondUserId')), findsOneWidget);
    });

    testWidgets('should not allow tap when follow is in progress', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        followStates: {testUserId: false},
        followingInProgress: {testUserId: true},
      ));

      // Reset the call tracking
      followToggleCalled = false;

      // Try to tap the follow button - should not trigger callback when loading
      final loadingButton = find.byKey(Key('follow_button_$testUserId'));
      expect(loadingButton, findsOneWidget);
      
      await tester.tap(loadingButton);
      await tester.pump();

      // Should not have called the toggle function (GestureDetector should be disabled)
      expect(followToggleCalled, isFalse);
    });

    testWidgets('should call onFollowToggle with correct user ID for each pet', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Tap first pet's follow button
      final firstFollowButton = find.byKey(Key('follow_button_$testUserId'));
      await tester.tap(firstFollowButton);
      await tester.pump();

      expect(followToggleCalled, isTrue);
      expect(followToggleUserId, equals(testUserId));

      // Reset and test second pet
      followToggleCalled = false;
      followToggleUserId = null;

      final secondFollowButton = find.byKey(Key('follow_button_user456'));
      await tester.tap(secondFollowButton);
      await tester.pump();

      expect(followToggleCalled, isTrue);
      expect(followToggleUserId, equals('user456'));
    });

    testWidgets('should switch from follow to unfollow state after successful toggle', (WidgetTester tester) async {
      // Start with not following (should show person_add icon)
      await tester.pumpWidget(createTestWidget(
        followStates: {testUserId: false},
      ));

      // Find the specific follow button and verify it contains person_add icon
      final followButton = find.byKey(Key('follow_button_$testUserId'));
      expect(followButton, findsOneWidget);
      
      // Look for person_add icon within the follow button
      final personAddIcon = find.descendant(
        of: followButton,
        matching: find.byIcon(Icons.person_add),
      );
      expect(personAddIcon, findsOneWidget);

      // Simulate successful follow by updating the widget state
      await tester.pumpWidget(createTestWidget(
        followStates: {testUserId: true},
      ));

      // Now the follow button should contain check icon instead
      final checkIcon = find.descendant(
        of: followButton,
        matching: find.byIcon(Icons.check),
      );
      expect(checkIcon, findsOneWidget);
      
      // And should not have person_add icon anymore
      expect(personAddIcon, findsNothing);
    });

    testWidgets('should switch from unfollow to follow state after successful toggle', (WidgetTester tester) async {
      // Start with following (should show check icon)
      await tester.pumpWidget(createTestWidget(
        followStates: {testUserId: true},
      ));

      // Find the specific follow button and verify it contains check icon
      final followButton = find.byKey(Key('follow_button_$testUserId'));
      expect(followButton, findsOneWidget);
      
      // Look for check icon within the follow button
      final checkIcon = find.descendant(
        of: followButton,
        matching: find.byIcon(Icons.check),
      );
      expect(checkIcon, findsOneWidget);

      // Simulate successful unfollow by updating the widget state
      await tester.pumpWidget(createTestWidget(
        followStates: {testUserId: false},
      ));

      // Now the follow button should contain person_add icon instead
      final personAddIcon = find.descendant(
        of: followButton,
        matching: find.byIcon(Icons.person_add),
      );
      expect(personAddIcon, findsOneWidget);
      
      // And should not have check icon anymore
      expect(checkIcon, findsNothing);
    });
  });
}
