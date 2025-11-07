import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'search_controller.dart' as search;
import 'widgets/search_widget.dart';
import '../business_home/widget/floating_action_button.dart';

class SearchView extends GetView<search.SearchController> {
  const SearchView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        body: SearchWidget(
          allPets: controller.allPetsList,
          filteredPets: controller.filteredPetsList,
          isLoadingPets: controller.isLoading,
          searchQuery: controller.currentSearchQuery,
          onSearchChanged: controller.updateSearchQuery,
          onClearSearch: controller.clearSearch,
          onFollowToggle: controller.handleFollowToggle,
          onPetTap: controller.navigateToPetProfile,
          followStates: controller.currentFollowStates,
          followingInProgress: controller.currentFollowingInProgress,
        ),
        bottomNavigationBar: BottomNavigationBarWidget(controller: controller.mapController),
      );
    });
  }
}