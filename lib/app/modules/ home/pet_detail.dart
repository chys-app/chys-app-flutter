import 'dart:developer';
import 'dart:io';

import 'package:chys/app/core/const/app_colors.dart';
import 'package:chys/app/core/const/app_image.dart';
import 'package:chys/app/modules/map/controllers/map_controller.dart';
import 'package:chys/app/modules/profile/controllers/profile_controller.dart';
import 'package:chys/app/routes/app_routes.dart';
import 'package:chys/app/services/common_service.dart';
import 'package:chys/app/services/date_time_service.dart';
import 'package:chys/app/services/short_message_utils.dart';
import 'package:chys/app/widget/common/image_viewer_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:geocoding/geocoding.dart';

class PetDetail extends StatefulWidget {
  const PetDetail({super.key});

  @override
  State<PetDetail> createState() => _PetDetailState();
}

class _PetDetailState extends State<PetDetail> {
  final controller = Get.find<MapController>();
  final profileController = Get.find<ProfileController>();
  final RxString resolvedAddress = "".obs;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadPetData();
    
    // Listen to currentIndex changes for auto-slide
    ever(controller.currentIndex, (int index) {
      if (_pageController.hasClients && _pageController.page?.round() != index) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _loadPetData() {
    final arguments = Get.arguments;
    if (arguments != null) {
      String petId = arguments.toString();
      controller.fetchPetProfile(petId: petId);
      log("Argument value is $petId");
    } else {
      controller.fetchPetProfile();
    }
  }

  IconData _getGenderIcon(String? sex) {
    if (sex == null) return Icons.pets;
    
    final sexLower = sex.toLowerCase().trim();
    if (sexLower == 'male' || sexLower == 'm') {
      return Icons.male;
    } else if (sexLower == 'female' || sexLower == 'f') {
      return Icons.female;
    } else {
      return Icons.pets; // Default icon for unknown gender
    }
  }

  void _showImageInFullScreen(String imageUrl, String title) {
    ImageViewerWidget.show(
      imageUrl: imageUrl,
      title: title,
      enableZoom: true,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Obx(() {
        if (controller.isDataLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF0095F6),
            ),
          );
        } else if (controller.petList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pets_outlined,
                  size: 64,
                  color: Color(0xFF8E8E93),
                ),
                SizedBox(height: 16),
                Text(
                  "No pet found, please try again",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        } else if (controller.petList[0] == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pets_outlined,
                  size: 64,
                  color: Color(0xFF8E8E93),
                ),
                SizedBox(height: 16),
                Text(
                  "Pet data is null",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        } else {
          final data = controller.petList[0];
          log("Pet data loaded: ${data.name}, Photos: ${data.photos?.length ?? 0}");
          log("🔍 Pet details - Sex: '${data.sex}', Photos: ${data.photos}, ProfilePic: ${data.profilePic}");
          log("🔍 Pet details - Weight: ${data.weight}, Size: ${data.size}, Color: ${data.color}");
          log("🔍 Pet details - Bio: ${data.bio}, PetType: ${data.petType}");
          log("Owner contact: ${data.ownerContactNumber}");
          log("Vet name: ${data.vetName}, Vet contact: ${data.vetContactNumber}");
          log("User model: ${data.userModel?.name}, ${data.userModel?.email}");
          log("Address data: ${data.address}");
          if (data.address != null) {
            log("City: ${data.address!.city}");
            log("State: ${data.address!.state}");
            log("Country: ${data.address!.country}");
          }
          log("User location: ${data.userModel?.location}");
          if (data.userModel?.location?.coordinates != null) {
            log("Coordinates: ${data.userModel!.location!.coordinates}");
            // Get address from coordinates if available
            if (data.userModel!.location!.coordinates!.length >= 2) {
              double lat = data.userModel!.location!.coordinates![1];
              double lng = data.userModel!.location!.coordinates![0];
              _getAddressFromCoordinates(lat, lng);
            }
          }

          // Process photos - include profile pic if available and photos are empty
          List<String> validPhotos = (data.photos ?? [])
              .where((url) => url.isNotEmpty)
              .map((url) => url)
              .toList();
          
          // If no photos but profile pic exists, use profile pic
          if (validPhotos.isEmpty && data.profilePic != null && data.profilePic!.isNotEmpty) {
            validPhotos = [data.profilePic!];
          }
          
          // Limit to 5 photos
          validPhotos = validPhotos.take(5).toList();
          
          log("📸 Valid photos count: ${validPhotos.length}");
          log("📸 Photos: $validPhotos");

          // Only start auto slide if there are multiple photos
          if (validPhotos.length > 1) {
            controller.startAutoSlide(validPhotos.length);
          }

          return CustomScrollView(
            slivers: [
              // App Bar with Pet Images
              SliverAppBar(
                expandedHeight: 400,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF0095F6),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => _handleBackNavigation(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {
                        _sharePetProfile(data);
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Image Carousel
                      PageView.builder(
                        itemCount:
                            validPhotos.isNotEmpty ? validPhotos.length : 1,
                        onPageChanged: controller.onPageChanged,
                        controller: _pageController,
                        itemBuilder: (context, index) {
                          log("🖼️ Building image at index $index, total photos: ${validPhotos.length}");
                          if (validPhotos.isNotEmpty && index < validPhotos.length) {
                            log("🖼️ Loading image: ${validPhotos[index]}");
                            return GestureDetector(
                              onTap: () => _showImageInFullScreen(validPhotos[index], data.name ?? 'Pet Image'),
                              child: Image.network(
                                validPhotos[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  log("❌ Image error at index $index: $error");
                                  return Container(
                                    color: const Color(0xFFE8E8E8),
                                    child: const Icon(
                                      Icons.pets,
                                      size: 80,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  );
                                },
                              ),
                            );
                          } else {
                            log("🖼️ Using fallback image at index $index");
                            return Container(
                              color: const Color(0xFFE8E8E8),
                              child: const Icon(
                                Icons.pets,
                                size: 80,
                                color: Color(0xFF8E8E93),
                              ),
                            );
                          }
                        },
                      ),
                      // Gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Pet name overlay
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  data.name ?? "Unknown Pet",
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _getGenderIcon(data.sex),
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${data.breed ?? "Unknown Breed"} • ${data.dateOfBirth != null ? DateTimeService.calculateAge(data.dateOfBirth!) : "Unknown Age"}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Page indicators - only show if there are multiple photos
                      if (validPhotos.length > 1)
                        Positioned(
                          bottom: 80,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                List.generate(validPhotos.length, (index) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                height: 8,
                                width: controller.currentIndex.value == index
                                    ? 24
                                    : 8,
                                decoration: BoxDecoration(
                                  color: controller.currentIndex.value == index
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Pet Details Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats Cards
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                emoji: "⚖️",
                                title: "Weight",
                                value:
                                    "${CommonService.kgToLbs(data.weight ?? 0)} lbs",
                                subtitle: "(${data.weight ?? 0} kg)",
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                emoji: "📏",
                                title: "Size",
                                value: data.size ?? "Unknown",
                                subtitle: "",
                                color: const Color(0xFF2196F3),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                emoji: "🎨",
                                title: "Color",
                                value: data.color ?? "Unknown",
                                subtitle: "",
                                color: const Color(0xFFFF9800),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // About Section
                      if (data.bio != null && data.bio!.isNotEmpty)
                        _buildInfoSection(
                          emoji: "🐾",
                          title: "About ${data.name}",
                          content: data.bio!,
                          color: const Color(0xFF9C27B0),
                        ),

                      const SizedBox(height: 20),

                      // Basic Information
                      _buildInfoSection(
                        emoji: "📋",
                        title: "Basic Information",
                        children: [
                          _buildInfoRow(
                              "🐕 Pet Type", data.petType ?? "Unknown"),
                          _buildInfoRow("🏷️ Microchip",
                              data.microchipNumber ?? "Not available"),
                          _buildInfoRow(
                              "🆔 Tag ID", data.tagId ?? "Not available"),
                          _buildInfoRow(
                              "🔍 Special Marks", data.marks ?? "None"),
                          _buildInfoRow("💉 Vaccination",
                              data.vaccinationStatus == true ? "Yes" : "No"),
                          _buildInfoRow("🚨 Lost Status",
                              data.lostStatus == true ? "Lost" : "Safe"),
                        ],
                        color: const Color(0xFF607D8B),
                      ),

                      const SizedBox(height: 20),

                      // Personality Traits
                      if (data.personalityTraits != null &&
                          data.personalityTraits!.isNotEmpty)
                        _buildInfoSection(
                          emoji: "⭐",
                          title: "Personality Traits",
                          children: data.personalityTraits!
                              .map(
                                (trait) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Text("• ",
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF0095F6))),
                                      Expanded(
                                        child: Text(
                                          trait,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF424242),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          color: const Color(0xFFFFC107),
                        ),

                      const SizedBox(height: 20),

                      // Allergies
                      if (data.allergies != null && data.allergies!.isNotEmpty)
                        _buildInfoSection(
                          emoji: "⚠️",
                          title: "Allergies",
                          children: data.allergies!
                              .map(
                                (allergy) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Text("• ",
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFFFF5722))),
                                      Expanded(
                                        child: Text(
                                          allergy,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF424242),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          color: const Color(0xFFFF5722),
                        ),

                      const SizedBox(height: 20),

                      // Special Needs
                      if (data.specialNeeds != null &&
                          data.specialNeeds!.isNotEmpty)
                        _buildInfoSection(
                          emoji: "🩺",
                          title: "Special Needs",
                          content: data.specialNeeds!,
                          color: const Color(0xFFE91E63),
                        ),

                      const SizedBox(height: 20),

                      // Feeding Instructions
                      if (data.feedingInstructions != null &&
                          data.feedingInstructions!.isNotEmpty)
                        _buildInfoSection(
                          emoji: "🍽️",
                          title: "Feeding Instructions",
                          content: data.feedingInstructions!,
                          color: const Color(0xFF795548),
                        ),

                      const SizedBox(height: 20),

                      // Daily Routine
                      if (data.dailyRoutine != null &&
                          data.dailyRoutine!.isNotEmpty)
                        _buildInfoSection(
                          emoji: "📅",
                          title: "Daily Routine",
                          content: data.dailyRoutine!,
                          color: const Color(0xFF3F51B5),
                        ),

                      const SizedBox(height: 20),

                      // Owner Contact Information
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: _buildContactSection(
                          emoji: "👤",
                          title: "Owner Contact",
                          name: data.userModel?.name ?? "Unknown",
                          phone: data.ownerContactNumber ?? "Not available",
                          email: data.userModel?.email ?? "Not available",
                          color: const Color(0xFF4CAF50),
                          isOwner: true, // Flag to identify owner contact
                          petData: data,
                        ),
                      ),

                      // Veterinary Information
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: _buildContactSection(
                          emoji: "🏥",
                          title: "Veterinary Contact",
                          name: data.vetName ?? "Not available",
                          phone: data.vetContactNumber ?? "Not available",
                          email: "Not available",
                          color: const Color(0xFF00BCD4),
                          petData: data,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Address Information
                      _buildInfoSection(
                        emoji: "📍",
                        title: "Location",
                        children: [
                          // Show address if available
                          if (data.address?.city != null &&
                              data.address!.city!.isNotEmpty)
                            _buildInfoRow("🏙️ City", data.address!.city!),
                          if (data.address?.state != null &&
                              data.address!.state!.isNotEmpty)
                            _buildInfoRow("🏛️ State", data.address!.state!),
                          if (data.address?.country != null &&
                              data.address!.country!.isNotEmpty)
                            _buildInfoRow("🌍 Country", data.address!.country!),

                          // Show resolved address if address is not available but coordinates exist
                          if ((data.address?.city == null ||
                                  data.address!.city!.isEmpty) &&
                              (data.address?.state == null ||
                                  data.address!.state!.isEmpty) &&
                              (data.address?.country == null ||
                                  data.address!.country!.isEmpty) &&
                              data.userModel?.location?.coordinates != null &&
                              data.userModel!.location!.coordinates!.length >=
                                  2)
                            Obx(() => _buildInfoRow(
                                "📍 Location",
                                resolvedAddress.value.isNotEmpty
                                    ? resolvedAddress.value
                                    : "Getting location...")),

                          // Show "Not available" if neither address nor coordinates exist
                          if ((data.address?.city == null ||
                                  data.address!.city!.isEmpty) &&
                              (data.address?.state == null ||
                                  data.address!.state!.isEmpty) &&
                              (data.address?.country == null ||
                                  data.address!.country!.isEmpty) &&
                              (data.userModel?.location?.coordinates == null ||
                                  data.userModel!.location!.coordinates!
                                          .length <
                                      2))
                            _buildInfoRow("📍 Location", "Not available"),
                        ],
                        color: const Color(0xFF673AB7),
                      ),

                      const SizedBox(height: 20),

                      // Pet Status Information
                      _buildInfoSection(
                        emoji: "📊",
                        title: "Pet Status",
                        children: [
                          _buildInfoRow(
                              "📅 Created",
                              data.createdAt != null
                                  ? "${data.createdAt!.day}/${data.createdAt!.month}/${data.createdAt!.year}"
                                  : "Unknown"),
                          _buildInfoRow(
                              "🔄 Updated",
                              data.updatedAt != null
                                  ? "${data.updatedAt!.day}/${data.updatedAt!.month}/${data.updatedAt!.year}"
                                  : "Unknown"),
                          _buildInfoRow("🆔 Pet ID", data.id ?? "Unknown"),
                        ],
                        color: const Color(0xFF9E9E9E),
                      ),

                      const SizedBox(height: 40),

                      // Contact Owner Button
                      if (profileController.userCurrentId.value !=
                          data.userModel?.id)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0095F6), Color(0xFF00C851)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0095F6).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () {
                              final userData = data.userModel!;
                              final ownerId = userData.id ?? "";
                              final ownerName = userData.name ?? "Unknown";
                              final ownerPhone = data.ownerContactNumber ?? "";
                              _openAppChat(ownerId, ownerName, ownerPhone);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.message,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Contact Owner",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      }),
    );
  }

  Widget _buildStatCard({
    required String emoji,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8E8E93),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoSection({
    required String emoji,
    required String title,
    String? content,
    List<Widget>? children,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF262626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (content != null)
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF424242),
                height: 1.5,
              ),
            ),
          if (children != null) ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF424242),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection({
    required String emoji,
    required String title,
    required String name,
    required String phone,
    required String email,
    required Color color,
    bool isOwner = false,
    required dynamic petData,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF262626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Contact Cards
          Row(
            children: [
              // Name Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Name",
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF262626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Phone Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            color: color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Phone",
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF262626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Email Card (Full Width)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.email,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Email",
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF262626),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    // Call functionality
                    if (phone != "Not available") {
                      _makePhoneCall(phone);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.phone,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Call",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    // Message functionality
                    if (phone != "Not available") {
                      if (isOwner) {
                        // For owner, open app chat using user ID
                        final userData = petData.userModel!;
                        final ownerId = userData.id ?? "";
                        final ownerName =
                            name != "Not available" ? name : "Unknown";
                        if (ownerId.isNotEmpty) {
                          _openAppChat(ownerId, ownerName, phone);
                        } else {
                          ShortMessageUtils.showError(
                              "Unable to open chat - user ID not found");
                        }
                      } else {
                        // For vet, use SMS
                        _sendMessage(phone);
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message,
                          color: color,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Message",
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to make phone call
  void _makePhoneCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        Get.snackbar(
          'Error',
          'Could not launch phone app',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to make phone call: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Helper method to send message
  void _sendMessage(String phoneNumber) async {
    try {
      final Uri messageUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {
          'body':
              'Hello! I saw your pet profile and would like to get in touch.',
        },
      );

      if (await canLaunchUrl(messageUri)) {
        await launchUrl(messageUri);
      } else {
        Get.snackbar(
          'Error',
          'Could not launch messaging app',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send message: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Helper method to share pet profile
  void _sharePetProfile(dynamic data) async {
    try {
      log("Pet id ${data.id}");

      // STEP 1: Generate Firebase Dynamic Link
      final DynamicLinkParameters parameters = DynamicLinkParameters(
        uriPrefix: 'https://ocdcleaner.page.link', // your Firebase domain
        link: Uri.parse('https://ocdcleaner.page.link/pet/${data.id}'),
        androidParameters: const AndroidParameters(
          packageName: 'com.example.chys',
        ),
        iosParameters: const IOSParameters(
          bundleId: 'com.app.chys',
        ),
        socialMetaTagParameters: SocialMetaTagParameters(
          title: 'Check out this pet on CHYS!',
          description: data.bio ?? 'Amazing pet profile',
          imageUrl: data.photos != null && data.photos!.isNotEmpty
              ? Uri.parse(data.photos!.first)
              : null,
        ),
      );

      final ShortDynamicLink shortLink =
          await FirebaseDynamicLinks.instance.buildShortLink(parameters);

      final String petUrl = shortLink.shortUrl.toString();
      log("Pet url is $petUrl");

      // STEP 2: Combine description + link
      final String contentToShare = '''
🐾 Check out this amazing pet!

Name: ${data.name ?? "Unknown"}
Breed: ${data.breed ?? "Unknown"}
Age: ${data.dateOfBirth != null ? DateTimeService.calculateAge(data.dateOfBirth!) : "Unknown"}

${data.bio != null && data.bio!.isNotEmpty ? "${data.bio!}\n" : ""}
Check it out: $petUrl

Shared via CHYS app 🐕🐱
''';

      XFile? previewFile;

      // STEP 3: If media exists, download first media
      if (data.photos != null && data.photos!.isNotEmpty) {
        final mediaUrl = data.photos![0];
        final mediaResponse = await http.get(Uri.parse(mediaUrl));

        final bytes = mediaResponse.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/shared_pet_preview.jpg');
        await file.writeAsBytes(bytes);

        previewFile = XFile(file.path);
      }

      // STEP 4: Share content
      await Share.shareXFiles(
        previewFile != null ? [previewFile] : [],
        text: contentToShare,
      );
    } catch (e) {
      log("Error sharing pet: $e");
      ShortMessageUtils.showError("Failed to share pet profile");
    }
  }

  // Helper method to handle back navigation
  void _handleBackNavigation() {
    try {
      // Try to go back, if it fails, go to home
      Get.back();
    } catch (e) {
      log("Cannot go back, navigating to home: $e");
      // If back navigation fails (no history), go to home
      Get.offAllNamed(AppRoutes.home);
    }
  }

  // Helper method to get address from coordinates
  Future<void> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String address = "";

        // Add street address if available
        if (placemark.street != null && placemark.street!.isNotEmpty) {
          address += placemark.street!;
        }

        // Add sublocality (neighborhood) if available
        if (placemark.subLocality != null &&
            placemark.subLocality!.isNotEmpty) {
          if (address.isNotEmpty) address += ", ";
          address += placemark.subLocality!;
        }

        // Add city
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          if (address.isNotEmpty) address += ", ";
          address += placemark.locality!;
        }

        // Add state/province
        if (placemark.administrativeArea != null &&
            placemark.administrativeArea!.isNotEmpty) {
          if (address.isNotEmpty) address += ", ";
          address += placemark.administrativeArea!;
        }

        // Add postal code if available
        if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
          if (address.isNotEmpty) address += " ";
          address += placemark.postalCode!;
        }

        // Add country
        if (placemark.country != null && placemark.country!.isNotEmpty) {
          if (address.isNotEmpty) address += ", ";
          address += placemark.country!;
        }

        if (address.isNotEmpty) {
          resolvedAddress.value = address;
          log("Resolved full address: $address");
        } else {
          resolvedAddress.value = "Location found";
        }
      } else {
        resolvedAddress.value = "Location not found";
      }
    } catch (e) {
      log("Error getting address from coordinates: $e");
      resolvedAddress.value = "Error getting location";
    }
  }

  // Helper method to open app chat
  void _openAppChat(String userId, String name, String phoneNumber) {
    try {
      // Navigate to chat detail with owner information
      Get.toNamed(AppRoutes.chatDetail, arguments: {
        "id": userId, // Using user ID for chat
        "name": name,
        "avatar": "assets/images/avatars/lisa.jpg", // Default avatar
        "phone": phoneNumber, // Keep phone for display
      });

      log("Opening app chat with: $name (ID: $userId)");
    } catch (e) {
      log("Error opening app chat: $e");
      ShortMessageUtils.showError("Failed to open chat");
    }
  }
}
