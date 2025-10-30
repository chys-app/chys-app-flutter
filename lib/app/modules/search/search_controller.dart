import 'dart:developer';
import 'package:get/get.dart';
import '../adored_posts/controller/controller.dart';
import '../../data/models/post.dart';

class SearchController extends GetxController {
  // Search query
  final searchQuery = ''.obs;
  
  // Loading state
  final isLoading = false.obs;
  
  // Posts controller for fetching and displaying posts
  late final AddoredPostsController postsController;
  
  // Filtered posts based on search
  final RxList<Posts> filteredPosts = <Posts>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    
    // Initialize posts controller with unique tag for search
    if (Get.isRegistered<AddoredPostsController>(tag: 'search')) {
      postsController = Get.find<AddoredPostsController>(tag: 'search');
    } else {
      postsController = Get.put(AddoredPostsController(), tag: 'search');
    }
    
    // Fetch posts when controller initializes
    fetchPosts();
    
    // Listen to search query changes
    ever(searchQuery, (_) => filterPosts());
    
    // Listen to posts changes
    ever(postsController.posts, (_) => filterPosts());
  }
  
  Future<void> fetchPosts() async {
    try {
      isLoading.value = true;
      await postsController.fetchAdoredPosts();
      filterPosts();
    } catch (e) {
      log('Error fetching posts for search: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  void updateSearchQuery(String query) {
    searchQuery.value = query.toLowerCase().trim();
  }
  
  void clearSearch() {
    searchQuery.value = '';
    filterPosts();
  }
  
  void filterPosts() {
    if (searchQuery.value.isEmpty) {
      // Show all posts when search is empty
      filteredPosts.assignAll(postsController.posts);
    } else {
      // Filter posts based on search query
      final query = searchQuery.value;
      filteredPosts.assignAll(
        postsController.posts.where((post) {
          // Search in description
          final descriptionMatch = post.description.toLowerCase().contains(query);
          
          // Search in creator name
          final creatorNameMatch = post.creator.name.toLowerCase().contains(query);
          
          // Search in tags
          final tagsMatch = post.tags.any((tag) => tag.toLowerCase().contains(query));
          
          return descriptionMatch || creatorNameMatch || tagsMatch;
        }).toList(),
      );
    }
    
    log('Filtered ${filteredPosts.length} posts from ${postsController.posts.length} total posts');
  }
  
  Future<void> refreshPosts() async {
    await postsController.fetchAdoredPosts(forceRefresh: true);
    filterPosts();
  }
  
  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}