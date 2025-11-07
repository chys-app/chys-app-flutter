import 'dart:developer';
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
      // Debug logging to see what data is being passed
      log("🔍 SearchView build - allPetsList length: ${controller.allPetsList.length}");
      log("🔍 SearchView build - filteredPetsList length: ${controller.filteredPetsList.length}");
      log("🔍 SearchView build - isLoading: ${controller.isLoading}");
      log("🔍 SearchView build - searchQuery: '${controller.currentSearchQuery}'");
      
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
          onDebugFollowStates: controller.debugFollowStates,
        ),
        bottomNavigationBar: BottomNavigationBarWidget(controller: controller.mapController),
      );
    });
  }
}