import 'package:chys/app/core/const/app_colors.dart';
import 'package:chys/app/core/const/app_image.dart';
import 'package:chys/app/core/const/app_text.dart';
import 'package:chys/app/modules/podcast/controllers/create_podcast_controller.dart';
import 'package:chys/app/routes/app_routes.dart';
import 'package:chys/app/widget/image/image_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../signup/widgets/custom_text_field.dart';

class InvitePodcastView extends GetView<CreatePodCastController> {
  InvitePodcastView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF4A5568), size: 20),
            onPressed: () => Get.back(),
          ),
        ),
        title: Text(
          "Invite to Podcast",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        centerTitle: true,
         actions: [
           // Debug button to load users from network
           IconButton(
             icon: const Icon(Icons.network_check, color: Color(0xFF4A5568)),
             onPressed: () {
               print("🌐 NETWORK BUTTON PRESSED");
               controller.loadUsersFromNetwork();
             },
             tooltip: "Load Network Users",
           ),
           // Debug button to load fallback users
           IconButton(
             icon: const Icon(Icons.people, color: Color(0xFF4A5568)),
             onPressed: () {
               print("👥 TEST USERS BUTTON PRESSED");
               controller.loadFallbackUsers();
             },
             tooltip: "Load Test Users",
           ),
           // Debug button to test data loading
           IconButton(
             icon: const Icon(Icons.refresh, color: Color(0xFF4A5568)),
             onPressed: () {
               print("🔄 REFRESH BUTTON PRESSED");
               controller.refreshUsers();
             },
             tooltip: "Refresh Users",
           ),
         ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFAFBFC), Color(0xFFF7FAFC)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Go Live with Your Pet Story",
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E40AF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Invite friends to join your podcast and share amazing pet stories together! 🐶✨🐱",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Search Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A202C).withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                   child: CustomTextField(
                     hintColor: const Color(0xFF94A3B8),
                     label: "Search friends...",
                     controller: controller.searchController,
                     onChanged: (value) {
                       print("🔍 SEARCH INPUT: '$value'");
                       controller.onSearchChanged(value);
                     },
                     fillColor: Colors.transparent,
                     borderColor: Colors.transparent,
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Users List Section
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A202C).withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                     child: RefreshIndicator(
                       onRefresh: () => controller.refreshUsers(),
                       child: Obx(() {
                         print("🔄 UI STATE UPDATE:");
                         print("   ⏳ Loading: ${controller.invitedUserLoading.value}");
                         print("   👥 Filtered users count: ${controller.filteredUsers.length}");
                         print("   📋 All users count: ${controller.usersList.length}");
                         print("   🔍 Search controller text: '${controller.searchController.text}'");
                         
                         if (controller.invitedUserLoading.value) {
                           print("   📱 Showing loading state");
                           return _buildLoadingState();
                         }
                         if (controller.filteredUsers.isEmpty) {
                           print("   📱 Showing empty state");
                           return _buildEmptyState();
                         }
                         print("   📱 Showing users list");
                         return _buildUsersList();
                       }),
                     ),
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Obx(() => controller.invitedUserIds.isNotEmpty
          ? Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton.extended(
                backgroundColor: const Color(0xFF10B981),
                elevation: 4,
                onPressed: () {
                  Get.toNamed(AppRoutes.startPodCost);
                  print("Invited Users: ${controller.invitedUserIds}");
                },
                icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                label: Text(
                  "Continue (${controller.invitedUserIds.length})",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink()),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.people_outline,
              color: Color(0xFF64748B),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Loading friends...",
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search_off,
              color: Color(0xFFD97706),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "No users found",
            style: GoogleFonts.inter(
              fontSize: 18,
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your search terms or pull down to refresh",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   ElevatedButton.icon(
                     onPressed: () {
                       print("🌐 EMPTY STATE NETWORK BUTTON PRESSED");
                       controller.loadUsersFromNetwork();
                     },
                     icon: const Icon(Icons.network_check, size: 18),
                     label: const Text("Load Network"),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFF8B5CF6),
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(8),
                       ),
                     ),
                   ),
                   const SizedBox(width: 12),
                   ElevatedButton.icon(
                     onPressed: () {
                       print("🔄 EMPTY STATE REFRESH BUTTON PRESSED");
                       controller.refreshUsers();
                     },
                     icon: const Icon(Icons.refresh, size: 18),
                     label: const Text("Refresh"),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFF3B82F6),
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(8),
                       ),
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  print("👥 EMPTY STATE TEST USERS BUTTON PRESSED");
                  controller.loadFallbackUsers();
                },
                icon: const Icon(Icons.people, size: 18),
                label: const Text("Load Test Users"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

   Widget _buildUsersList() {
     print("📋 BUILDING USERS LIST");
     print("   👥 Total filtered users: ${controller.filteredUsers.length}");
     print("   📊 All filtered users data: ${controller.filteredUsers}");
     
     return ListView.separated(
       padding: const EdgeInsets.all(16),
       itemCount: controller.filteredUsers.length,
       separatorBuilder: (_, __) => const SizedBox(height: 12),
       itemBuilder: (context, index) {
         final user = controller.filteredUsers[index];
         final userId = user['id'];
         
         print("👤 Building user item $index:");
         print("   🆔 User ID: $userId");
         print("   📋 User data: $user");
         
         return Obx(() {
           final isSelected = controller.invitedUserIds.contains(userId);
           return GestureDetector(
            onTap: () => controller.toggleInvite(userId),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                     // Avatar
                     Container(
                       decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         border: Border.all(
                           color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
                           width: 2,
                         ),
                       ),
                       child: _buildUserAvatar(user, isSelected),
                     ),

                    const SizedBox(width: 16),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name'],
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user['location'],
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Selection Indicator
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          );
        });
       },
     );
   }

   // Helper method to generate user initials
   String _generateInitials(String name) {
     if (name.isEmpty) return '?';
     
     final words = name.trim().split(' ');
     if (words.isEmpty) return '?';
     
     if (words.length == 1) {
       // Single word - return first two characters
       return words[0].substring(0, words[0].length > 1 ? 2 : 1).toUpperCase();
     } else {
       // Multiple words - return first character of first and last word
       final firstInitial = words[0].isNotEmpty ? words[0][0] : '';
       final lastInitial = words[words.length - 1].isNotEmpty ? words[words.length - 1][0] : '';
       return '${firstInitial}${lastInitial}'.toUpperCase();
     }
   }

   // Helper method to get avatar background color based on initials
   Color _getAvatarColor(String initials) {
     final colors = [
       const Color(0xFF3B82F6), // Blue
       const Color(0xFF10B981), // Green
       const Color(0xFFF59E0B), // Yellow
       const Color(0xFFEF4444), // Red
       const Color(0xFF8B5CF6), // Purple
       const Color(0xFF06B6D4), // Cyan
       const Color(0xFF84CC16), // Lime
       const Color(0xFFF97316), // Orange
     ];
     
     final hash = initials.hashCode;
     return colors[hash.abs() % colors.length];
   }

   // Helper method to build user avatar with initials fallback
   Widget _buildUserAvatar(Map<String, dynamic> user, bool isSelected) {
     final userName = user['name']?.toString() ?? 'Unknown User';
     final initials = _generateInitials(userName);
     
     // Try to get avatar from multiple sources
     String? avatarUrl;
     
     // 1. Try user's profilePic
     final userProfilePic = user['profilePic']?.toString();
     if (userProfilePic != null && userProfilePic.trim().isNotEmpty && 
         (userProfilePic.startsWith('http://') || userProfilePic.startsWith('https://'))) {
       avatarUrl = userProfilePic;
     }
     
     // 2. Try user's avatar field
     if (avatarUrl == null) {
       final userAvatar = user['avatar']?.toString();
       if (userAvatar != null && userAvatar.trim().isNotEmpty && 
           (userAvatar.startsWith('http://') || userAvatar.startsWith('https://'))) {
         avatarUrl = userAvatar;
       }
     }
     
     // 3. Try first pet's profilePic as fallback
     if (avatarUrl == null && user['pets'] is List && (user['pets'] as List).isNotEmpty) {
       final pets = user['pets'] as List;
       for (final pet in pets) {
         if (pet is Map<String, dynamic>) {
           final petProfilePic = pet['profilePic']?.toString();
           if (petProfilePic != null && petProfilePic.trim().isNotEmpty && 
               (petProfilePic.startsWith('http://') || petProfilePic.startsWith('https://'))) {
             avatarUrl = petProfilePic;
             break;
           }
         }
       }
     }
     
     // DEBUG: Log user data for avatar
     print("🖼️ AVATAR DEBUG for user: ${userName}");
     print("   📋 Full user data: $user");
     print("   🖼️ User profilePic: '${user['profilePic']}'");
     print("   🖼️ User avatar: '${user['avatar']}'");
     print("   🐾 Pets count: ${user['pets'] is List ? (user['pets'] as List).length : 0}");
     if (user['pets'] is List && (user['pets'] as List).isNotEmpty) {
       final pets = user['pets'] as List;
       for (int i = 0; i < pets.length; i++) {
         if (pets[i] is Map<String, dynamic>) {
           final pet = pets[i] as Map<String, dynamic>;
           print("   🐾 Pet $i: ${pet['name']} - profilePic: '${pet['profilePic']}'");
         }
       }
     }
     print("   🖼️ Final avatar URL: '$avatarUrl'");
     print("   👤 User name: '$userName'");
     print("   🔤 Generated initials: '$initials'");
     
     // Check if we have a valid avatar URL
     final hasValidAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;
     
     print("   ✅ Has valid avatar: $hasValidAvatar");
     
     if (hasValidAvatar) {
       print("   🖼️ Using network image: $avatarUrl");
       return CircleAvatar(
         radius: 24,
         backgroundImage: NetworkImage(avatarUrl),
         backgroundColor: const Color(0xFFF3F4F6),
         onBackgroundImageError: (exception, stackTrace) {
           print("   ❌ Network image failed to load: $exception");
           print("   🔄 Falling back to initials: $initials");
         },
         child: null, // This will be overridden by backgroundImage
       );
     } else {
       print("   🔤 Using initials: $initials");
       // Show initials when no valid avatar (null, empty string, or invalid URL)
       return CircleAvatar(
         radius: 24,
         backgroundColor: _getAvatarColor(initials),
         child: Text(
           initials,
           style: GoogleFonts.inter(
             color: Colors.white,
             fontWeight: FontWeight.w600,
             fontSize: 16,
           ),
         ),
       );
     }
   }
 }
