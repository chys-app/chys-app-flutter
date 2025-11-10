import 'dart:developer';
import 'package:chys/app/core/const/app_colors.dart';
import 'package:chys/app/core/const/app_text.dart';
import 'package:chys/app/data/models/own_profile.dart';
import 'package:chys/app/data/models/pet_profile.dart';
import 'package:chys/app/modules/adored_posts/controller/controller.dart';
import 'package:chys/app/modules/map/controllers/map_controller.dart';
import 'package:chys/app/modules/profile/controllers/profile_controller.dart';
import 'package:chys/app/modules/products/controller/products_controller.dart';
import 'package:chys/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../widget/common/post_grid_widget.dart';
import '../../../widget/common/profile_tabs_widget.dart';
import '../../../widget/shimmer/cat_quote_shimmer.dart';
import 'create_fundraise_view.dart';

class ProfileView extends StatefulWidget {
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> 
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final mapController = Get.find<MapController>();
  final profileController = Get.find<ProfileController>();
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    // Remove the listener to prevent unnecessary rebuilds that cause flicker
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app resumes
      profileController.refreshProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final argument = Get.arguments;
    bool isUserId = argument != null;

    // Controllers for posts - use separate instance for profile to avoid conflicts
    final AddoredPostsController postController = Get.put(AddoredPostsController(), tag: 'profile');
    final ProductsController productsController = Get.find<ProductsController>();

    log("Profile view using controller with tag: 'profile'");

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        log("User id is $isUserId");

        if (isUserId) {
          log("User id is $argument");
          await profileController.fetchProfilee(
              userId: argument, isFromUserProfile: true);
          // Fetch posts for this specific user (force refresh to avoid cache mixups)
          log("Fetching posts for user ID: $argument");
          await postController.fetchAdoredPosts(userId: argument, forceRefresh: true);
        } else {
          log("User come here");
          await profileController.fetchProfilee(isFromUserProfile: true);
          // Use profile ID when available; fallback to stored current user ID
          final currentUserId =
              profileController.profile.value?.id ?? profileController.userCurrentId.value;
          log("Fetching posts for current user ID: $currentUserId");
          if (currentUserId.isNotEmpty) {
            await postController.fetchAdoredPosts(userId: currentUserId, forceRefresh: true);
          }
          
          // Fetch wishlist products
          await productsController.fetchWishlist();
        }
      } catch (e) {
        log("Error in profile page initialization: $e");
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            try {
              // Refresh profile data and posts
              await profileController.refreshProfileData();
              final id = isUserId
                  ? argument
                  : (profileController.profile.value?.id ??
                  profileController.userCurrentId.value);
              await postController.fetchAdoredPosts(
                userId: id,
                forceRefresh: true,
              );
              // Refresh wishlist
              await productsController.fetchWishlist();
            } catch (e) {
              log("Error refreshing profile: $e");
            }
          },
          child: Obx(() {
            if (profileController.isLoading.value) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 0,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 20),
                      ),
                      onPressed: () => Get.back(),
                    ),
                    title: const Text(
                      "Profile",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    centerTitle: true,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),

                          // Profile Header Shimmer
                          _buildProfileHeaderShimmer(),

                          const SizedBox(height: 12),

                          // Bio Section Shimmer
                          _buildBioSectionShimmer(),

                          const SizedBox(height: 12),

                          // Stats Section Shimmer
                          _buildStatsSectionShimmer(),

                          const SizedBox(height: 12),

                          // Action Buttons Shimmer
                          _buildActionButtonsShimmer(),

                          const SizedBox(height: 12),


                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // Check if profile data is available
            if (profileController.profile.value == null && !profileController.isLoading.value) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 0,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 20),
                      ),
                      onPressed: () => Get.back(),
                    ),
                    title: const Text(
                      "Profile",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    centerTitle: true,
                  ),
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline, size: 64, color: Color(0xFF0095F6)),
                          SizedBox(height: 16),
                          Text(
                            "No Profile Data",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF262626),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Pull down to refresh",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return CustomScrollView(
                slivers: [
                  // Custom App Bar
                  _buildSliverAppBar(),

                  // Profile Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Header
                          _buildProfileHeader(),

                          const SizedBox(height: 12),

                          // Bio Section
                          _buildBioSection(),

                          const SizedBox(height: 12),

                          // Stats Section
                          _buildStatsSection(postController),

                          const SizedBox(height: 12),

                          // Action Buttons
                          _buildActionButtons(argument),
                        ],
                      ),
                    ),
                  ),
                  
                  // Posts Display - Full width without padding
                  SliverToBoxAdapter(
                    child: _buildPostsSection(postController, productsController),
                  ),
                ]

            );
          }
          ),
        ),
      ),
    );

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
          child: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
        onPressed: () => Get.back(),
      ),
      title: Obx(() {
        final profileData = profileController.profile.value;
        return Text(
          profileData?.name ?? "Profile",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        );
      }),
      centerTitle: true,
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

  Widget _buildProfileHeader() {
    return Obx(() {
      final profileData = profileController.profile.value;
      final pets = profileController.userPets;
      final petCount = pets.length;
      final hasMultiplePets = petCount > 1;
      final userPet = profileController.userPet.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasMultiplePets)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.transparent,
                        width: 0,
                      ),
                    ),
                    child: _buildPetProfileAvatar(userPet, size: 80),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: _buildProfileAvatar(profileData),
                  ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userPet?.name ?? profileData?.name ?? "User Name",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "@${(userPet?.name ?? profileData?.name ?? "username").toLowerCase().replaceAll(' ', '')}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildBirthdaySection(),
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

  Widget _buildBirthdaySection() {
    return Obx(() {
      final userPet = profileController.userPet.value;
      
      if (userPet?.dateOfBirth == null) {
        return const SizedBox.shrink();
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text("🎁", style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            _formatBirthday(userPet!.dateOfBirth!),
            style: TextStyle(
              color: AppColors.blue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    });
  }

  String _formatBirthday(DateTime date) {
    return "${date.month}/${date.day}/${date.year}";
  }

  Widget _buildBioSection() {
    return Obx(() {
      final profileData = profileController.profile.value;
      if (profileData?.bio == null || profileData!.bio!.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Text(
          profileData.bio!,
          style: const TextStyle(
            fontSize: 14,
            color: const Color(0xFF262626),
            height: 1.4,
          ),
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
            count: profileController.followersCount.value.toString(),
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
            count: profileController.followingCount.value.toString(),
            label: "Following",
            icon: Icons.person_add_outlined,
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

  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey.shade300,
    );
  }


  Widget _buildActionButtons(String? argument) {
    // This view is only for current user's profile
    // Other users' profiles will use OtherUserProfileView
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
            label: "Edit Profile",
            onTap: () {
              // Navigate to pet edit flow
              final hasPet = profileController.userPet.value != null;
              if (hasPet) {
                Get.toNamed(AppRoutes.petEditSelectionFlow);
              } else {
                // Navigate to add pet flow if no pet exists
                Get.toNamed(AppRoutes.editProfile);
              }
            },
          ),
          const SizedBox(width: 8),
          _buildVerticalDivider(),
          const SizedBox(width: 8),
          _buildActionButton(
            label: "Raise Funds",
            onTap: () {
              // Navigate to create fundraise view
              Get.to(() => CreateFundraiseView());
            },
          ),
          const SizedBox(width: 11),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback? onTap,
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
          boxShadow: isDisabled ? null : [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
      ),
    );
  }

  Widget _buildPostsSection(AddoredPostsController postController, ProductsController productsController) {
    return ProfileTabsWidget.standard(
      tabController: tabController,
      postsTabContent: _buildPostsTabContent(postController),
      donateTabContent: _buildDonateTabContent(),
      wishlistTabContent: _buildWishlistTabContent(productsController),
    );
  }

  Widget _buildPostsTabContent(AddoredPostsController postController) {
    return Obx(() {
      if (postController.isLoading.value) {
        return ListView.builder(
          physics: const ScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: 3,
          itemBuilder: (_, __) => const CatQuoteCardShimmer(),
        );
      }

      if (postController.posts.isEmpty) {
        return SizedBox(
          height: Get.height * 0.45,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  size: 48,
                  color: const Color(0xFF0095F6), // App's primary blue color
                ),
                const AppText(
                  text: "No posts yet",
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0095F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const AppText(
                    text: "Share your first post to get started!",
                    fontSize: 14,
                    color: Color(0xFF6E6E6E), // App's text secondary color
                    fontWeight: FontWeight.w500,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                // Add a subtle decorative element
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0095F6),
                        Color(0xFF00C851),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return _buildGridView(postController);
    });
  }

  Widget _buildDonateTabContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite,
            size: 48,
            color: Color(0xFFE91E63),
          ),
          SizedBox(height: 16),
          Text(
            "Donate Feature",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF262626),
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Coming soon!",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistTabContent(ProductsController productsController) {
    return Obx(() {
      // Show loading indicator while fetching wishlist
      if (productsController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Get wishlist products
      final wishlistProducts = productsController.products.where((product) => 
        productsController.isInWishlist(product.id)
      ).toList();

      if (wishlistProducts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                "Your wishlist is empty",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Add products to your wishlist to see them here",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }

      // Show wishlist products in a grid
      return LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final crossAxisCount = screenWidth > 600 ? 4 : 3;

          return GridView.count(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.75, // Slightly more compact to prevent overflow
            children: List.generate(wishlistProducts.length, (index) {
              final product = wishlistProducts[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          color: Colors.grey.shade100,
                        ),
                        child: product.media.isNotEmpty
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(
                                  product.media.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => 
                                    Icon(Icons.image, color: Colors.grey.shade400, size: 32),
                                ),
                              )
                            : Icon(Icons.image, color: Colors.grey.shade400, size: 32),
                      ),
                    ),
                    // Product info
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.description,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0095F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          );
        },
      );
    });
  }



  
  Widget _buildGridView(AddoredPostsController postController) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final crossAxisCount = screenWidth > 600 ? 4 : 3;

        return GridView.count(
          shrinkWrap: true,
          physics: const ScrollPhysics(),
          padding: EdgeInsets.zero,
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 1.0, // Square tiles
          children: List.generate(postController.posts.length, (index) {
            return PostGridWidget(
              post: postController.posts[index],
              addoredPostsController: postController,
              // Enable thumbnail generation for videos
              disableThumbnailGeneration: false,
            );
          }),
        );
      },
    );
  }


  // Shimmer Loading Methods
  Widget _buildProfileHeaderShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile Picture Shimmer
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Shimmer
                  Container(
                    height: 20,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Location Shimmer
                  Container(
                    height: 16,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioSectionShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bio Title Shimmer
            Container(
              height: 18,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            // Bio Text Shimmer
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 16,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSectionShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(3, (index) => Column(
            children: [
              // Number Shimmer
              Container(
                height: 24,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              // Label Shimmer
              Container(
                height: 14,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildActionButtonsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(OwnProfileModel? profileData, {double size = 80}) {
    final imageUrl = profileData?.profilePic;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildInitialsAvatar(profileData?.name, size: size);
            },
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: _buildInitialsAvatar(profileData?.name, size: size),
      ),
    );
  }

  Widget _buildPetProfileAvatar(PetModel? userPet, {double size = 80}) {
    final imageUrl = userPet?.profilePic;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildInitialsAvatar(userPet?.name, size: size);
            },
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: _buildInitialsAvatar(userPet?.name, size: size),
      ),
    );
  }

  Widget _buildInitialsAvatar(String? name, {double size = 80}) {
    final initials = _getInitials(name ?? "");
    return Container(
      color: AppColors.blue.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.3,
            fontWeight: FontWeight.bold,
            color: AppColors.blue,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) {
      return "?";
    }
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}