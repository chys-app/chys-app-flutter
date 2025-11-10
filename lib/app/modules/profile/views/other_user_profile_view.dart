import 'dart:developer';
import 'package:chys/app/core/const/app_colors.dart';
import 'package:chys/app/core/utils/app_size.dart';
import 'package:chys/app/data/models/own_profile.dart';
import 'package:chys/app/data/models/product.dart';
import 'package:chys/app/modules/adored_posts/controller/controller.dart';
import 'package:chys/app/modules/donate/controller/donate_controller.dart';
import 'package:chys/app/modules/map/controllers/map_controller.dart';
import 'package:chys/app/modules/profile/controllers/other_user_profile_controller.dart';
import 'package:chys/app/modules/podcast/controllers/create_podcast_controller.dart';
import 'package:chys/app/modules/products/controller/products_controller.dart';
import 'package:chys/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../widget/common/wishlist_product_widget.dart';
import '../../../widget/common/profile_tabs_widget.dart';
import '../../../widget/common/post_grid_widget.dart';
import '../../../widget/shimmer/cat_quote_shimmer.dart';
import '../../../services/date_time_service.dart';
import '../../../services/payment_services.dart';
import '../../../services/custom_Api.dart';
import '../../../core/controllers/loading_controller.dart';
import '../../../services/short_message_utils.dart';

class OtherUserProfileView extends StatefulWidget {
  const OtherUserProfileView({super.key});

  @override
  State<OtherUserProfileView> createState() => _OtherUserProfileViewState();
}

class _OtherUserProfileViewState extends State<OtherUserProfileView> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final mapController = Get.find<MapController>();
  // Use dedicated controller for other user profiles
  final otherUserProfileController =
      Get.put(OtherUserProfileController(), tag: 'other_user_profile');
  final CustomApiService customApiService = Get.put(CustomApiService());
  
  late final TabController tabController;
  late final AddoredPostsController postController;
  late final DonateController donateController;
  late final ProductsController productsController;
  
  // Store the user's wishlist products
  final RxList<Products> userWishlistProducts = <Products>[].obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize tab controller
    tabController = TabController(length: 3, vsync: this);
    
    // Initialize controllers
    postController = Get.put(AddoredPostsController(), tag: 'other_profile');
    donateController = Get.put(DonateController(), tag: 'other_profile_donate');
    productsController = Get.put(ProductsController(), tag: 'other_profile_products');
    
    // Fetch initial data
    _initializeData();
  }

  Future<void> _initializeData() async {
    final argument = Get.arguments as String?;
    
    if (argument != null) {
      // Load data in parallel for better performance
      await Future.wait([
        otherUserProfileController.fetchOtherUserProfile(argument),
        postController.fetchAdoredPosts(userId: argument, forceRefresh: true),
        donateController.fetchDonations(),
      ]);
      
      // Fetch user-specific wishlist separately
      log('🔍 Fetching wishlist for user: $argument');
      final wishlist = await productsController.fetchUserWishlist(argument);
      log('🔍 Received wishlist: ${wishlist.length} items');
      userWishlistProducts.assignAll(wishlist);
      log('🔍 Assigned to reactive list: ${userWishlistProducts.length} items');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    tabController.dispose();
    postController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app resumes
      _initializeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final argument = Get.arguments as String?;

    if (argument == null) {
      Get.back();
      return const Scaffold();
    }

    log("Other user profile view using controller with tag: 'other_profile'");

    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              try {
                // Refresh profile data and posts for the specific user
                await otherUserProfileController
                    .fetchOtherUserProfile(argument);
                await postController.fetchAdoredPosts(
                    userId: argument, forceRefresh: true);
                await donateController.fetchDonations();
                await productsController.fetchWishlist();
              } catch (e) {
                log("Error refreshing profile: $e");
              }
            },
            child: CustomScrollView(
              slivers: [
                // Custom App Bar
                _buildSliverAppBar(),

                // Profile Content
                SliverToBoxAdapter(
                  child: Obx(() {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header - Show loading state if needed
                        if (otherUserProfileController.isLoading.value)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: _buildLoadingState(),
                          )
                        else ...[
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: _buildProfileHeader(),
                          ),
                          const SizedBox(height: 12),

                          // Birthday & Gift Features - At the top
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: _buildBirthdaySection(),
                          ),

                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: _buildStatsSection(postController),
                          ),
                          const SizedBox(height: 16),

                          // Action Buttons Section
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: _buildActionButtonsSection(),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Tabbed Content Section
                        _buildTabbedSection(),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: Colors.black),
        ),
        onPressed: () => Get.back(),
      ),
      title: Obx(() {
        final profileData = otherUserProfileController.profile.value;
        final userPet = otherUserProfileController.userPet.value;
        return Text(
          userPet?.name ?? profileData?.name ?? "Profile",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        );
      }),
      centerTitle: true,
      actions: [
        // Block/Report Button
        Obx(() {
          final profileData = otherUserProfileController.profile.value;
          if (profileData == null) return const SizedBox.shrink();

          return PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.more_vert, size: 20, color: Colors.black),
            ),
            onSelected: (value) {
              if (value == 'block') {
                _showBlockDialog(profileData.id ?? '');
              } else if (value == 'report') {
                _showReportDialog(profileData.id ?? '');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Block User'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text('Report User'),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  String _buildFullAddress(OwnProfileModel? profileData) {
    if (profileData == null) return "Location";

    final addressParts = <String>[];

    if (profileData.address?.isNotEmpty == true) {
      addressParts.add(profileData.address!);
    }
    if (profileData.city?.isNotEmpty == true) {
      addressParts.add(profileData.city!);
    }
    if (profileData.state?.isNotEmpty == true) {
      addressParts.add(profileData.state!);
    }
    if (profileData.zipCode?.isNotEmpty == true) {
      addressParts.add(profileData.zipCode!);
    }
    if (profileData.country?.isNotEmpty == true) {
      addressParts.add(profileData.country!);
    }

    if (addressParts.isEmpty) return "Location";

    return addressParts.join(', ');
  }

  Widget _buildAddressDisplay(OwnProfileModel? profileData) {
    if (profileData == null) {
      return Text(
        "Location",
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      );
    }

    final addressParts = <String>[];

    if (profileData.address?.isNotEmpty == true) {
      addressParts.add(profileData.address!);
    }
    if (profileData.city?.isNotEmpty == true) {
      addressParts.add(profileData.city!);
    }
    if (profileData.state?.isNotEmpty == true) {
      addressParts.add(profileData.state!);
    }
    if (profileData.zipCode?.isNotEmpty == true) {
      addressParts.add(profileData.zipCode!);
    }
    if (profileData.country?.isNotEmpty == true) {
      addressParts.add(profileData.country!);
    }

    if (addressParts.isEmpty) {
      return Text(
        "Location",
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: addressParts
          .map((part) => Text(
                part,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Compact loading animation
          const CircularProgressIndicator(
            color: Color(0xFF0095F6),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          const Text(
            "Loading Profile...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Obx(() {
      final profileData = otherUserProfileController.profile.value;
      final pets = otherUserProfileController.userPets;
      final userPet = otherUserProfileController.userPet.value;
      if (profileData == null) {
        return const SizedBox.shrink(); // Don't show anything while loading
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: pets.isNotEmpty ? Colors.transparent : Colors.grey.shade300,
                      width: pets.isNotEmpty ? 0 : 1,
                    ),
                  ),
                  child: pets.isNotEmpty
                      ? _buildPetProfileAvatar(userPet)
                      : _buildPetProfileAvatar(userPet),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userPet?.name ?? profileData.name ?? "User Name",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "@${(userPet?.name ?? profileData.name ?? "username").toLowerCase().replaceAll(' ', '')}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildGiftButton(profileData.id ?? ''),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildFollowButton(profileData.id ?? ''),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatsSection(AddoredPostsController postController) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactStatItem(
            count: otherUserProfileController.followersCount.value.toString(),
            label: "Followers",
            icon: Icons.people_outline,
          ),
          _buildVerticalDivider(),
          _buildCompactStatItem(
            count: postController.posts.length.toString(),
            label: "Posts",
            icon: Icons.grid_on_outlined,
          ),
          _buildVerticalDivider(),
          _buildCompactStatItem(
            count: otherUserProfileController.followingCount.value.toString(),
            label: "Following",
            icon: Icons.person_add_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      {required String count, required String label, required IconData icon}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildCompactPetDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              "$label:",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(
      {required String count, required String label, required IconData icon}) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonsSection() {
    return Obx(() {
      final profileData = otherUserProfileController.profile.value;
      final userPet = otherUserProfileController.userPet.value;

      if (profileData == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Pet Profile Button - Open Pet Profile Details
            _buildActionButton(
              label: "Pet Profile",
              onTap: () {
                if (userPet != null) {
                  _navigateToPetProfile(userPet);
                }
              },
            ),
            // Follow Button
            if (!otherUserProfileController.isCurrentUser)
              _buildFollowActionButton(profileData.id ?? ''),
          ],
        ),
      );
    });
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: 90,
        height: 44,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade300 : AppColors.blue,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDisabled ? Colors.grey.shade600 : Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowActionButton(String userId) {
    return Obx(() {
      final isFollowing = otherUserProfileController.isFollowing.value;
      final isCurrentUser = otherUserProfileController.isCurrentUser;
      
      return GestureDetector(
        onTap: !isCurrentUser && userId.isNotEmpty
            ? () {
                otherUserProfileController.followUnfollow(userId);
              }
            : null,
        child: Container(
          width: 90,
          height: 44,
          decoration: BoxDecoration(
            color: isFollowing ? Colors.transparent : AppColors.blue,
            border: isFollowing ? Border.all(color: Colors.grey.shade300, width: 1.5) : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: !isFollowing
                ? [
                    BoxShadow(
                      color: AppColors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              isFollowing ? 'Following' : 'Follow',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isFollowing ? Colors.grey.shade700 : Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildFollowButton(String userId) {
    return Obx(() {
      // Use the controller's isCurrentUser getter for proper comparison
      final isCurrentUser = otherUserProfileController.isCurrentUser;
      final currentUserId = otherUserProfileController.userCurrentId.value;
      final profileId = otherUserProfileController.profile.value?.id;

      log("Follow button - Current user ID: '$currentUserId', Profile ID: '$profileId', Target user ID: '$userId', Is current user: $isCurrentUser");
      log("Follow button - User ID empty: ${userId.isEmpty}, Current user ID empty: ${currentUserId.isEmpty}");

      // Debug: Check if button should be enabled
      final shouldEnableButton = !isCurrentUser && userId.isNotEmpty;
      log("Follow button - Should enable: $shouldEnableButton");

      // If current user ID is empty, try to reload it
      if (currentUserId.isEmpty) {
        log("Current user ID is empty, attempting to reload...");
        otherUserProfileController.reloadCurrentUserId();
      }

      final isFollowing = otherUserProfileController.isFollowing.value;

      return GestureDetector(
        onTap: shouldEnableButton
            ? () {
                log("Follow button tapped for user ID: $userId");
                log("Is current user: $isCurrentUser");
                log("Current following state: $isFollowing");
                otherUserProfileController.followUnfollow(userId);
              }
            : null,
        child: SvgPicture.asset(
          !shouldEnableButton
              ? 'assets/images/paw_outline.svg'
              : (isFollowing
                  ? 'assets/images/paw_filled_outline.svg'
                  : 'assets/images/paw_outline.svg'),
          width: 60,
          height: 60,
        ),
      );
    });
  }

  Widget _buildGiftButton(String userId) {
    return Obx(() {
      // Use the controller's isCurrentUser getter for proper comparison
      final isCurrentUser = otherUserProfileController.isCurrentUser;
      final currentUserId = otherUserProfileController.userCurrentId.value;
      final profileId = otherUserProfileController.profile.value?.id;
      final userPet = otherUserProfileController.userPet.value;

      log("Gift button - Current user ID: '$currentUserId', Profile ID: '$profileId', Target user ID: '$userId', Is current user: $isCurrentUser");

      // Debug: Check if button should be enabled
      final shouldEnableButton = userId.isNotEmpty;
      log("Gift button - Should enable: $shouldEnableButton");

      // If current user ID is empty, try to reload it
      if (currentUserId.isEmpty) {
        log("Current user ID is empty, attempting to reload...");
        otherUserProfileController.reloadCurrentUserId();
      }

      // Get gift text - show pet's birthday date
      String giftText = "Send Gift";
      if (userPet?.dateOfBirth != null) {
        giftText = _formatBirthday(userPet!.dateOfBirth!);
      }

      return GestureDetector(
        onTap: shouldEnableButton
            ? () {
                log("Gift button tapped for user ID: $userId");
                _showGiftDialog(userId);
              }
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text("🎁", style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              giftText,
              style: TextStyle(
                color: AppColors.blue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTabbedSection() {
    return Column(
      children: [
        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TabBar(
            controller: tabController,
            labelColor: const Color(0xFF0095F6),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF0095F6),
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.grid_on, size: 20),
                text: ' Posts',
              ),
              Tab(
                icon: Icon(Icons.favorite, size: 20),
                text: ' Donate',
              ),
              Tab(
                icon: Icon(Icons.shopping_bag, size: 20),
                text: ' Wishlist',
              ),
            ],
          ),
        ),
        
        // Tab Content
        SizedBox(
          height: Get.height * 0.6, // Adjust height as needed
          child: ProfileTabsWidget.standard(
            tabController: tabController,
            postsTabContent: _buildPostsTabContent(),
            donateTabContent: _buildDonateTabContent(),
            wishlistTabContent: _buildWishlistTabContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTabContent() {
    return Obx(() {
      if (postController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Filter posts by type 'post'
      final filteredPosts = postController.posts.where((post) => 
        post.type == 'post' || post.type == null
      ).toList();

      if (filteredPosts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: Color(0xFF0095F6),
              ),
              const SizedBox(height: 16),
              Text(
                "No posts yet",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "This user hasn't posted anything yet",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }

      final screenWidth = MediaQuery.of(Get.context!).size.width;
      final crossAxisCount = screenWidth > 900
          ? 4
          : screenWidth > 600
              ? 3
              : 2;

      return StaggeredGridView.countBuilder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemCount: filteredPosts.length,
        itemBuilder: (context, index) {
          final post = filteredPosts[index];
          return PostGridWidget(
            post: post,
            addoredPostsController: postController,
            onTapCard: () => Get.toNamed('/post-detail', arguments: post.id),
          );
        },
        staggeredTileBuilder: (index) => StaggeredTile.count(
          1,
          (filteredPosts[index].description.length % 3) * 0.1 + 1.2,
        ),
      );
    });
  }

  Widget _buildDonateTabContent() {
    return Obx(() {
      if (postController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Filter posts by type 'fundraise'
      final fundraisePosts = postController.posts.where((post) => 
        post.type == 'fundraise'
      ).toList();

      if (fundraisePosts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite_border,
                size: 48,
                color: Color(0xFF0095F6),
              ),
              const SizedBox(height: 16),
              Text(
                "No fundraisers yet",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "This user hasn't started any fundraisers",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: fundraisePosts.length,
        itemBuilder: (context, index) {
          final post = fundraisePosts[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.media.isNotEmpty)
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: post.media[0].isNotEmpty
                        ? Image.network(
                            post.media[0],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 48),
                          )
                        : const Icon(Icons.image, size: 48),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.description,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (post.fundCount != null && post.fundedAmount != null) ...[
                        Text(
                          'Raised: \$${post.fundedAmount} / ${post.fundCount} backers',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF00C851),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Get.toNamed('/post-detail', arguments: post.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0095F6),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Support Fundraiser',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildWishlistTabContent() {
    return Obx(() {
      log('🔍 Wishlist UI Debug - Loading: ${productsController.isLoading.value}, Products count: ${userWishlistProducts.length}');
      
      if (productsController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (userWishlistProducts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: Color(0xFF0095F6),
              ),
              const SizedBox(height: 16),
              Text(
                "Wishlist is empty",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "This user hasn't added any products to their wishlist",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7, // Even more height to prevent cutoff
        ),
        itemCount: userWishlistProducts.length,
        itemBuilder: (context, index) {
          final product = userWishlistProducts[index];
          return WishlistProductWidget(product: product);
        },
      );
    });
  }

  Widget _buildPostsTab(AddoredPostsController postController) {
    return Obx(() {
      if (postController.isLoading.value) {
        return const CatQuoteCardShimmer();
      }

      if (postController.posts.isEmpty) {
        return const Center(
          child: Column(
            children: [
              Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "No posts yet",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      final screenWidth = MediaQuery.of(Get.context!).size.width;
      final crossAxisCount = screenWidth > 900
          ? 4
          : screenWidth > 600
              ? 3
              : 2;

      return StaggeredGridView.countBuilder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        itemCount: postController.posts.length,
        itemBuilder: (context, index) {
          final post = postController.posts[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PostGridWidget(
              post: post,
              addoredPostsController: postController,
              // Enable thumbnail generation for videos
              disableThumbnailGeneration: false,
            ),
          );
        },
        staggeredTileBuilder: (index) {
          // Fixed height ratio for all posts to make them the same height
          const double heightRatio = 1.2;
          return StaggeredTile.count(1, heightRatio);
        },
      );
    });
  }

  Widget _buildProfessionalPetCard(dynamic pet) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0095F6),
            Color(0xFF00C851),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0095F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.network(
                pet.profilePic ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFF8F8F8),
                  child: const Icon(
                    Icons.pets,
                    size: 80,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
            // Gradient overlay for better text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pet Name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pet.name ?? "Unknown Pet",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Pet Details
                    Row(
                      children: [
                        _buildDetailChip(
                          icon: Icons.category,
                          label: pet.breed ?? "Unknown Breed",
                        ),
                        const SizedBox(width: 8),
                        if (pet.dateOfBirth != null)
                          _buildDetailChip(
                            icon: Icons.cake,
                            label: _calculatePetAge(pet.dateOfBirth!),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Additional Info
                    if (pet.petType != null)
                      _buildDetailChip(
                        icon: Icons.pets,
                        label: pet.petType!,
                      ),
                  ],
                ),
              ),
            ),
            // Tap overlay
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    try {
                      // Navigate to home detail with pet data
                      Get.toNamed(AppRoutes.homeDetail, arguments: pet.id);
                    } catch (e) {
                      print('Error tapping pet card: $e');
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _calculatePetAge(dynamic dateOfBirth) {
    try {
      DateTime birthDate;
      if (dateOfBirth is String) {
        birthDate = DateTime.parse(dateOfBirth);
      } else if (dateOfBirth is DateTime) {
        birthDate = dateOfBirth;
      } else {
        return "Unknown age";
      }

      return DateTimeService.calculateAge(birthDate);
    } catch (e) {
      return "Unknown age";
    }
  }

  Widget _buildPetProfileAvatar(dynamic userPet) {
    if (userPet?.profilePic != null && userPet!.profilePic!.isNotEmpty) {
      return CircleAvatar(
        radius: 35,
        backgroundColor: Colors.grey.shade100,
        backgroundImage: NetworkImage(userPet.profilePic!),
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback to initials if image fails to load
        },
        child:
            userPet.profilePic!.contains('null') || userPet.profilePic!.isEmpty
                ? _buildInitialsAvatar(userPet.name, 35)
                : null,
      );
    } else {
      return _buildInitialsAvatar(userPet?.name, 35);
    }
  }

  Widget _buildInitialsAvatar(String? userName, double radius) {
    final initials = getUserInitials(userName);
    final color = getAvatarColor(initials);

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Birthday & Gift Features - Only for Pet Owners
  Widget _buildBirthdaySection() {
    return Obx(() {
      final userPet = otherUserProfileController.userPet.value;
      final isCurrentUser = otherUserProfileController.isCurrentUser;

      // Only show birthday section for pet owners (current user)
      if (!isCurrentUser || userPet == null) {
        return const SizedBox.shrink();
      }

      // If no birthday data, show a placeholder
      if (userPet.dateOfBirth == null) {
        return _buildBirthdayPlaceholder(userPet);
      }

      final isBirthdayToday = _isBirthdayToday(userPet.dateOfBirth!);
      final isBirthdayThisWeek = _isBirthdayThisWeek(userPet.dateOfBirth!);
      final isBirthdayIn7Days = _isBirthdayIn7Days(userPet.dateOfBirth!);

      // Show if birthday is today, this week, or in 7 days
      if (!isBirthdayToday && !isBirthdayThisWeek && !isBirthdayIn7Days) {
        return const SizedBox.shrink();
      }

      return Column(
        children: [
          // Birthday Display - Prominent at top
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade50, Colors.purple.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.pink.shade200,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () => _showBirthdayGiftDialog(userPet),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "🎁",
                      style: TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBirthdayToday
                              ? "🎉 It's ${userPet.name}'s Birthday Today 🎉"
                              : isBirthdayIn7Days
                                  ? "🎂 ${userPet.name}'s Birthday in 7 Days"
                                  : "${userPet.name}'s Birthday Coming Up",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.pink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatBirthday(userPet.dateOfBirth!),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tap anywhere to send birthday gifts 🎁",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  void _showGiftDialog(String userId) {
    Get.bottomSheet(
      _GiftBottomSheet(
        userId: userId,
        onConfirm: (amount, giftType) async {
          try {
            Get.find<LoadingController>().show();
            await PaymentServices.stripePayment(
                amount, "gift_${userId}", Get.context!, onSuccess: () async {
              // Update UI state if needed
              final response = await customApiService.postRequest(
                  'posts/fundRaise/user/${userId}',
                  {"amount": amount, "giftType": giftType});

              log("Gift response: $response");
              Get.snackbar(
                "🎁 Gift Sent",
                "Your $giftType gift of \$$amount has been sent",
                backgroundColor: const Color(0xFF0095F6),
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
                duration: const Duration(seconds: 3),
              );
            });
          } catch (e) {
            log("Error sending gift: $e");
            ShortMessageUtils.showError("Failed to send gift");
          } finally {
            Get.find<LoadingController>().hide();
          }
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildGiftOption(String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendLove(dynamic userPet) {
    Get.back();
    Get.snackbar(
      "❤️ Love Sent",
      "You sent love to ${userPet.name}",
      backgroundColor: Colors.pink,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
  }

  void _sendGift(dynamic userPet) {
    Get.back();
    Get.snackbar(
      "🎁 Gift Sent",
      "Your gift has been sent to ${userPet.name}",
      backgroundColor: const Color(0xFF0095F6),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  void _sendDonation(dynamic userPet) {
    Get.back();
    Get.snackbar(
      "💰 Donation Sent",
      "Your donation has been sent to ${userPet.name}",
      backgroundColor: const Color(0xFF00C851),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  bool _isBirthdayToday(DateTime dateOfBirth) {
    final today = DateTime.now();
    return today.month == dateOfBirth.month && today.day == dateOfBirth.day;
  }

  bool _isBirthdayThisWeek(DateTime dateOfBirth) {
    final today = DateTime.now();
    final nextBirthday =
        DateTime(today.year, dateOfBirth.month, dateOfBirth.day);

    // If birthday has passed this year, check next year
    if (nextBirthday.isBefore(today)) {
      final nextYearBirthday =
          DateTime(today.year + 1, dateOfBirth.month, dateOfBirth.day);
      return nextYearBirthday.difference(today).inDays <= 7;
    }

    return nextBirthday.difference(today).inDays <= 7;
  }

  bool _isBirthdayIn7Days(DateTime dateOfBirth) {
    final today = DateTime.now();
    final nextBirthday =
        DateTime(today.year, dateOfBirth.month, dateOfBirth.day);

    // If birthday has passed this year, check next year
    if (nextBirthday.isBefore(today)) {
      final nextYearBirthday =
          DateTime(today.year + 1, dateOfBirth.month, dateOfBirth.day);
      return nextYearBirthday.difference(today).inDays == 7;
    }

    return nextBirthday.difference(today).inDays == 7;
  }

  String _formatBirthday(DateTime dateOfBirth) {
    return "${dateOfBirth.month}/${dateOfBirth.day}/${dateOfBirth.year}";
  }

  Widget _buildPetPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.pets,
        size: 24,
        color: Colors.grey,
      ),
    );
  }

  void _navigateToPetProfile(dynamic userPet) {
    log("Pet card tapped for: ${userPet.name}");
    // Navigate to pet details page instead of showing donation dialog
    Get.toNamed(AppRoutes.homeDetail, arguments: userPet.id);
  }

  void _showPetGiftDialog(dynamic userPet) {
    Get.bottomSheet(
      _PetDonationBottomSheet(
        userPet: userPet,
        onConfirm: (amount, donationType) async {
          final oldFundCount = 0; // We'll track this if needed
          try {
            Get.find<LoadingController>().show();
            await PaymentServices.stripePayment(
                amount, "pet_donation_${userPet.id}", Get.context!,
                onSuccess: () async {
              // Update UI state if needed
              final response = await customApiService.postRequest(
                  'posts/fundRaise/pet/${userPet.id}',
                  {"amount": amount, "donationType": donationType});

              log("Pet donation response: $response");
              Get.snackbar(
                "🐾 Donation Sent",
                "Your $donationType donation of \$$amount has been sent to ${userPet.name}",
                backgroundColor: const Color(0xFF00C851),
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
                duration: const Duration(seconds: 3),
              );
            });
          } catch (e) {
            log("Error donating to pet: $e");
            ShortMessageUtils.showError("Failed to send donation");
          } finally {
            Get.find<LoadingController>().hide();
          }
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showBirthdayGiftDialog(dynamic userPet) {
    Get.bottomSheet(
      _BirthdayGiftBottomSheet(
        userPet: userPet,
        onConfirm: (amount, giftType) async {
          try {
            Get.find<LoadingController>().show();
            await PaymentServices.stripePayment(
                amount, "birthday_gift_${userPet.id}", Get.context!,
                onSuccess: () async {
              // Update UI state if needed
              final response = await customApiService.postRequest(
                  'posts/fundRaise/pet/${userPet.id}',
                  {"amount": amount, "giftType": giftType, "isBirthday": true});

              log("Birthday gift response: $response");
              Get.snackbar(
                "🎂 Birthday Gift Sent",
                "Your $giftType birthday gift of \$$amount has been sent to ${userPet.name}",
                backgroundColor: const Color(0xFF0095F6),
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
                duration: const Duration(seconds: 3),
              );
            });
          } catch (e) {
            log("Error sending birthday gift: $e");
            ShortMessageUtils.showError("Failed to send birthday gift");
          } finally {
            Get.find<LoadingController>().hide();
          }
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildPetDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetDetailCard(String label, String value, String emoji) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(String userId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Block User'),
        content: const Text('Are you sure you want to block this user?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement block user functionality
              Get.back();
              Get.snackbar(
                'User Blocked',
                'User has been blocked successfully',
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(String userId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Report User'),
        content: const Text('Are you sure you want to report this user?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement report user functionality
              Get.back();
              Get.snackbar(
                'User Reported',
                'User has been reported successfully',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
            },
            child: const Text('Report', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdayPlaceholder(dynamic userPet) {
    return Column(
      children: [
        // Birthday Display Placeholder
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.pink[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.pink[200]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showGiftDialog(userPet),
                child: const Text(
                  "🎁",
                  style: TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "12/25/2023",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${userPet.name}'s birthday is coming up",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "(When you click on 🎁 you are directed to send a gift or donate)",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Birthday Notifications Placeholder
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.pink[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.pink[200]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications, color: Colors.pink, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Birthday Notifications",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text("+ notifications to all followers"),
              const Text("a week before the birthday"),
              const SizedBox(height: 4),
              Text(
                "\"${userPet.name}'s birthday reminder:",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Text("send ❤️ or 🎁\""),
            ],
          ),
        ),
      ],
    );
  }

  // Method to invite user to podcast directly via API
  Future<void> _inviteUserToPodcast(String userId) async {
    try {
      Get.find<LoadingController>().show();

      final currentUserId = otherUserProfileController.userCurrentId.value;
      final userPet = otherUserProfileController.userPet.value;

      // Get the current user's existing podcast
      String? podcastId;

      try {
        // Try to get existing podcast from CreatePodCastController
        if (Get.isRegistered<CreatePodCastController>()) {
          final podcastController = Get.find<CreatePodCastController>();
          if (podcastController.podcasts.isNotEmpty) {
            // Get the most recent podcast created by current user
            final currentUserPodcasts = podcastController.podcasts
                .where((podcast) => podcast.host.id == currentUserId)
                .toList();

            if (currentUserPodcasts.isNotEmpty) {
              podcastId = currentUserPodcasts.first.id;
              log("Found existing podcast ID: $podcastId");
            }
          }
        }
      } catch (e) {
        log("Error getting existing podcast: $e");
      }

      // Update the podcast with the guest information using PUT
      if (podcastId != null) {
        final updateResponse = await customApiService.putRequest(
          'podcast/$podcastId',
          {
            "guests": [userId],
          },
        );

        log("Podcast update response: $updateResponse");

        Get.snackbar(
          "🎙️ Podcast Invitation Sent",
          "Successfully invited user to podcast",
          backgroundColor: const Color(0xFF0095F6),
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      } else {
        // No existing podcast found, ask user to schedule one first
        log("No existing podcast found, asking user to schedule one...");
        Get.find<LoadingController>().hide();

        _showSchedulePodcastDialog(userId);
        return;
      }
    } catch (e) {
      log("Error inviting user to podcast: $e");
      ShortMessageUtils.showError("Failed to send podcast invitation");
    } finally {
      Get.find<LoadingController>().hide();
    }
  }

  // Method to show dialog asking user to schedule a podcast first
  void _showSchedulePodcastDialog(String userId) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0095F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.mic,
                color: Color(0xFF0095F6),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Schedule Podcast First",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "You need to schedule a podcast before inviting guests.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0095F6).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF0095F6).withOpacity(0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF0095F6),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Go to the podcast section to create and schedule your podcast, then come back to invite guests.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0095F6),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Navigate to podcast creation/scheduling
              Get.toNamed(AppRoutes.invitePodcast);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0095F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              "Schedule Podcast",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Pet Donation Bottom Sheet - Beautiful donation selection with predefined amounts
class _PetDonationBottomSheet extends StatefulWidget {
  final dynamic userPet;
  final Function(String amount, String donationType) onConfirm;
  const _PetDonationBottomSheet(
      {required this.userPet, required this.onConfirm});
  @override
  State<_PetDonationBottomSheet> createState() =>
      _PetDonationBottomSheetState();
}

class _PetDonationBottomSheetState extends State<_PetDonationBottomSheet> {
  bool _isLoading = false;
  String? _selectedDonationType;
  String? _selectedAmount;

  final List<Map<String, dynamic>> _donationOptions = [
    {
      "emoji": "🐾",
      "type": "Care",
      "amount": "5",
      "color": const Color(0xFF0095F6)
    },
    {
      "emoji": "🦴",
      "type": "Treats",
      "amount": "10",
      "color": const Color(0xFF0095F6)
    },
    {
      "emoji": "🏥",
      "type": "Health",
      "amount": "15",
      "color": const Color(0xFF0095F6)
    },
    {
      "emoji": "🛁",
      "type": "Grooming",
      "amount": "25",
      "color": const Color(0xFF0095F6)
    },
    {
      "emoji": "🎾",
      "type": "Toys",
      "amount": "50",
      "color": const Color(0xFF0095F6)
    },
    {
      "emoji": "🏠",
      "type": "Home",
      "amount": "100",
      "color": const Color(0xFF0095F6)
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.7,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          _buildHeader(),
          const SizedBox(height: 24),
          _buildDonationGrid(),
          const SizedBox(height: 24),
          _buildCustomAmount(),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0095F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.card_giftcard,
                color: AppColors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Support ${widget.userPet.name}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue,
                      ),
                    ),
                    Text(
                      "Your contribution helps create more tail wags and happy meows",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDonationGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Choose Your Donation",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _donationOptions.length,
          itemBuilder: (context, index) {
            final donation = _donationOptions[index];
            final isSelected = _selectedDonationType == donation['type'] &&
                _selectedAmount == donation['amount'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDonationType = donation['type'];
                  _selectedAmount = donation['amount'];
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? donation['color'].withOpacity(0.2)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isSelected ? donation['color'] : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: donation['color'].withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      donation['emoji'],
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      donation['type'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? donation['color'] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "\$${donation['amount']}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? donation['color']
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomAmount() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _selectedAmount = value;
          _selectedDonationType = "Custom Donation";
        });
      },
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: "Enter custom amount",
        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF0095F6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0095F6), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasSelection =
        _selectedDonationType != null && _selectedAmount != null;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  hasSelection ? const Color(0xFF0095F6) : Colors.grey.shade300,
              foregroundColor:
                  hasSelection ? Colors.white : Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: hasSelection ? 4 : 0,
            ),
            onPressed: hasSelection && !_isLoading
                ? () async {
                    setState(() => _isLoading = true);
                    await widget.onConfirm(
                        _selectedAmount!, _selectedDonationType!);
                    setState(() => _isLoading = false);
                    Get.back();
                  }
                : null,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("🐾", style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        "Donate",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Get.back(),
            child: const Text(
              "Cancel",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Gift Bottom Sheet - Beautiful gift selection with predefined amounts
class _GiftBottomSheet extends StatefulWidget {
  final String userId;
  final Function(String amount, String giftType) onConfirm;
  const _GiftBottomSheet({required this.userId, required this.onConfirm});
  @override
  State<_GiftBottomSheet> createState() => _GiftBottomSheetState();
}

class _GiftBottomSheetState extends State<_GiftBottomSheet> {
  bool _isLoading = false;
  String? _selectedGiftType;
  String? _selectedAmount;

  final List<Map<String, dynamic>> _giftOptions = [
    {
      "emoji": "❤️",
      "type": "Love",
      "amount": "5",
      "color": const Color(0xFF0095F6)
    },
    {
      "emoji": "⚽",
      "type": "Ball",
      "amount": "10",
      "color": const Color(0xFF0095F6)
    },
    {
      "emoji": "🧸",
      "type": "Toy",
      "amount": "15",
      "color": const Color(0xFF0095F6)
    },
    {
      "emoji": "😊",
      "type": "Joy",
      "amount": "20",
      "color": const Color(0xFF0095F6)
    },
    {
      "emoji": "👑",
      "type": "Majesty",
      "amount": "50",
      "color": const Color(0xFF0095F6)
    },
    {
      "emoji": "✨",
      "type": "Magic",
      "amount": "100",
      "color": const Color(0xFF0095F6)
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.7,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ListView(
        // mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          _buildHeader(),
          const SizedBox(height: 24),
          _buildGiftGrid(),
          const SizedBox(height: 24),
          _buildCustomAmount(),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0095F6).withOpacity(0.1),
                const Color(0xFF0095F6).withOpacity(0.05)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF0095F6).withOpacity(0.3), width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0095F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  size: 32,
                  color: Color(0xFF0095F6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Send a Special Gift",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0095F6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Choose a gift to show your appreciation",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGiftGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Choose Your Gift",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _giftOptions.length,
          itemBuilder: (context, index) {
            final gift = _giftOptions[index];
            final isSelected = _selectedGiftType == gift['type'] &&
                _selectedAmount == gift['amount'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGiftType = gift['type'];
                  _selectedAmount = gift['amount'];
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? gift['color'].withOpacity(0.2)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? gift['color'] : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: gift['color'].withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      gift['emoji'],
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gift['type'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? gift['color'] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "\$${gift['amount']}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? gift['color'] : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomAmount() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _selectedAmount = value;
          _selectedGiftType = "Custom Gift";
        });
      },
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: "Enter custom amount",
        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF0095F6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0095F6), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasSelection = _selectedGiftType != null && _selectedAmount != null;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  hasSelection ? const Color(0xFF0095F6) : Colors.grey.shade300,
              foregroundColor:
                  hasSelection ? Colors.white : Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: hasSelection ? 4 : 0,
            ),
            onPressed: hasSelection && !_isLoading
                ? () async {
                    setState(() => _isLoading = true);
                    await widget.onConfirm(
                        _selectedAmount!, _selectedGiftType!);
                    setState(() => _isLoading = false);
                    Get.back();
                  }
                : null,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("🎁", style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        "Send Gift",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Get.back(),
            child: const Text(
              "Cancel",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Birthday Gift Bottom Sheet - Special birthday-themed gift selection
class _BirthdayGiftBottomSheet extends StatefulWidget {
  final dynamic userPet;
  final Function(String amount, String giftType) onConfirm;
  const _BirthdayGiftBottomSheet(
      {required this.userPet, required this.onConfirm});
  @override
  State<_BirthdayGiftBottomSheet> createState() =>
      _BirthdayGiftBottomSheetState();
}

class _BirthdayGiftBottomSheetState extends State<_BirthdayGiftBottomSheet> {
  bool _isLoading = false;
  String? _selectedGiftType;
  String? _selectedAmount;

  final List<Map<String, dynamic>> _birthdayGiftOptions = [
    {
      "emoji": "❤️",
      "type": "Love",
      "amount": "5",
      "color": const Color(0xFF0095F6)
    },
    {
      "emoji": "⚽",
      "type": "Ball",
      "amount": "10",
      "color": const Color(0xFF0095F6)
    },
    {
      "emoji": "🧸",
      "type": "Toy",
      "amount": "15",
      "color": const Color(0xFF0095F6)
    },
    {
      "emoji": "😊",
      "type": "Joy",
      "amount": "20",
      "color": const Color(0xFF0095F6)
    },
    {
      "emoji": "👑",
      "type": "Majesty",
      "amount": "50",
      "color": const Color(0xFF0095F6)
    },
    {
      "emoji": "✨",
      "type": "Magic",
      "amount": "100",
      "color": const Color(0xFF0095F6)
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.7,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          _buildHeader(),
          const SizedBox(height: 24),
          _buildBirthdayGiftGrid(),
          const SizedBox(height: 24),
          _buildCustomAmount(),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0095F6).withOpacity(0.1),
                const Color(0xFF0095F6).withOpacity(0.05)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF0095F6).withOpacity(0.3), width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0095F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  "🎂",
                  style: TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Send Gift to ${widget.userPet.name}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0095F6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Choose a gift to show your appreciation",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBirthdayGiftGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Choose Your Gift",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _birthdayGiftOptions.length,
          itemBuilder: (context, index) {
            final gift = _birthdayGiftOptions[index];
            final isSelected = _selectedGiftType == gift['type'] &&
                _selectedAmount == gift['amount'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGiftType = gift['type'];
                  _selectedAmount = gift['amount'];
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? gift['color'].withOpacity(0.2)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? gift['color'] : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: gift['color'].withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      gift['emoji'],
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gift['type'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? gift['color'] : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "\$${gift['amount']}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? gift['color'] : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomAmount() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _selectedAmount = value;
          _selectedGiftType = "Custom Birthday Gift";
        });
      },
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: "Enter custom amount (minimum \$1)",
        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF0095F6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0095F6), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildActionButtons() {
    final hasSelection = _selectedGiftType != null && _selectedAmount != null;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  hasSelection ? const Color(0xFF0095F6) : Colors.grey.shade300,
              foregroundColor:
                  hasSelection ? Colors.white : Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: hasSelection ? 4 : 0,
            ),
            onPressed: hasSelection && !_isLoading
                ? () async {
                    setState(() => _isLoading = true);
                    await widget.onConfirm(
                        _selectedAmount!, _selectedGiftType!);
                    setState(() => _isLoading = false);
                    Get.back();
                  }
                : null,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("🎁", style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        "Send Gift",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => Get.back(),
            child: const Text(
              "Cancel",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
