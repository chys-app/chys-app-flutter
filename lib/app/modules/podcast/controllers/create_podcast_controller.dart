import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chys/app/services/common_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
 
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_image.dart';
import '../../../core/controllers/loading_controller.dart';
import '../../../data/models/podcast_model.dart';
import '../../../services/http_service.dart';
import '../../../services/pet_ownership_service.dart';

class CreatePodCastController extends GetxController {
  final GlobalKey previewKey = GlobalKey();
  final searchController = TextEditingController();
  final invitedUserLoading = false.obs;
  final usersList = <Map<String, dynamic>>[].obs;
  final filteredUsers = <Map<String, dynamic>>[].obs;
  var invitedUserIds = <String>[].obs;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final totalAmountController = TextEditingController();
  final scheduledAt = Rxn<DateTime>();
  final formKey = GlobalKey<FormState>();
  var selectedImage = Rx<File?>(null);

  var networkImageUrl = ''.obs;

  // Schedule

  // Text customization
  var heading1Text = 'LOREM IPSUM DOLOR SIT'.obs;
  var heading1Font = 'Roboto'.obs;
  var heading1Color = Rx<Color>(Colors.brown);

  var heading2Text = 'with RACHEL ZOE'.obs;
  var heading2Font = 'Roboto'.obs;
  var heading2Color = Colors.white.obs;

  var bannerLineText = 'LOREM IPSUM DOLOR SIT'.obs;
  var bannerLineFont = 'Roboto'.obs;
  var bannerLineColor = Colors.white.obs;
  var bannerBackgroundColor = Rx<Color>(Colors.brown);

  var selectedTemplate = 0.obs;
  final List<Color> templateColors = [
    Colors.grey.shade800,
    Colors.brown.shade400,
    Colors.blue.shade600,
    Colors.red.shade400,
    Colors.green.shade500,
    Colors.orange.shade600,
    Colors.teal.shade600,
    Colors.indigo.shade700,
    Colors.purple.shade500,
    Colors.cyan.shade400,
  ];
  RxBool isPodcastLoading = false.obs;
  final RxList<Podcast> podcasts = <Podcast>[].obs;
  final List<String> availableFonts = [
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Raleway',
    'Poppins',
    'Nunito',
    'Playfair Display',
    'Merriweather',
    'Ubuntu',
    'Oswald',
    'Slabo 27px',
    'Crimson Text',
    'Libre Baskerville'
  ];
  Future<String?> saveWidgetAsImage([int retryCount = 0]) async {
    const int maxRetries = 20; // Increased for iOS release mode

    try {
      if (retryCount >= maxRetries) {
        log('❌ Max retries reached for saving widget image');
        return null;
      }

      // Ensure the widget is properly rendered
      if (previewKey.currentContext == null) {
        log('❌ Preview key context is null');
        return null;
      }

      RenderRepaintBoundary? boundary = previewKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        log('❌ RenderRepaintBoundary not found');
        return null;
      }

      // In iOS release mode, we need to ensure the widget is fully rendered
      if (boundary.debugNeedsPaint || !boundary.debugNeedsLayout) {
        // Increased delay for iOS release mode
        await Future.delayed(Duration(milliseconds: 200 + (retryCount * 50)));

        // Force a frame to be rendered
        WidgetsBinding.instance.addPostFrameCallback((_) {
          boundary.markNeedsPaint();
        });

        return await saveWidgetAsImage(retryCount + 1);
      }

      // Additional check for iOS release mode
      if (!boundary.debugNeedsPaint && boundary.debugNeedsLayout) {
        await Future.delayed(const Duration(milliseconds: 100));
        return await saveWidgetAsImage(retryCount + 1);
      }

      // Ensure the boundary is attached and ready
      if (!boundary.attached) {
        log('❌ RenderRepaintBoundary not attached');
        return null;
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        log('❌ Failed to get byte data from image');
        return null;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final String dir = (await getTemporaryDirectory()).path;
      final String filePath =
          '$dir/widget_preview_${DateTime.now().millisecondsSinceEpoch}.png';

      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      log('✅ Widget image saved at: $filePath');
      return filePath;
    } catch (e) {
      CommonService.showError("Failed to save widget image: $e");
      log('❌ Failed to save widget image: $e');
      return null;
    }
  }

  // Alternative method for iOS release mode
  Future<String?> saveWidgetAsImageIOS() async {
    try {
      // Wait for the next frame to ensure widget is rendered
      await Future.delayed(const Duration(milliseconds: 300));

      // Schedule a frame and wait for it to complete
      await Future.delayed(const Duration(milliseconds: 100));

      if (previewKey.currentContext == null) {
        log('❌ Preview key context is null');
        return null;
      }

      final RenderRepaintBoundary boundary = previewKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // Force a repaint and wait
      boundary.markNeedsPaint();
      await Future.delayed(const Duration(milliseconds: 200));

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        log('❌ Failed to get byte data from image');
        return null;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final String dir = (await getTemporaryDirectory()).path;
      final String filePath =
          '$dir/widget_preview_${DateTime.now().millisecondsSinceEpoch}.png';

      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      log('✅ Widget image saved at: $filePath');
      return filePath;
    } catch (e) {
      CommonService.showError("Failed to save widget image: $e");
      log('❌ Failed to save widget image: $e');
      return null;
    }
  }

  void showColorPicker(BuildContext context, Color currentColor,
      Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: onColorChanged,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Got it'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  bool validateForm() {
    if (!formKey.currentState!.validate()) return false;

    if (scheduledAt.value == null) {
      Get.snackbar("Error", "Please select a scheduled date.",
          backgroundColor: AppColors.error, colorText: Colors.white);
      return false;
    }

    return true;
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      selectedImage.value = File(image.path);
    }
  }

  void pickScheduleDate(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          primaryColor: AppColors.primary,
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
          buttonTheme:
              const ButtonThemeData(textTheme: ButtonTextTheme.primary),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        scheduledAt.value = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
  }

  // Proof Images logic
  final RxList<File> proofImages = <File>[].obs;
  static const int maxProofImages = 5;

  Future<void> pickProofImage() async {
    if (proofImages.length >= maxProofImages) {
      CommonService.showError("You can only add up to 5 images.");
      return;
    }
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      proofImages.add(File(image.path));
    }
  }

  void removeProofImage(int index) {
    if (index >= 0 && index < proofImages.length) {
      proofImages.removeAt(index);
    }
  }

  Future<void> createPodCast() async {
    try {
      // Check pet ownership first
      final petService = PetOwnershipService.instance;
      if (!petService.canCreatePodcasts) {
      //  petService.showPodcastRestriction();
        return;
      }
      
      if (selectedImage.value == null) {
        CommonService.showError("Please select image first");
        return;
      }
      // Proof images validation
      if (proofImages.isEmpty) {
        CommonService.showError("Please add at least one proof image.");
        return;
      }
      Get.find<LoadingController>().show();

    
      String? edittedImagePath;

      // Use iOS-specific method for iOS release mode
      if (!kIsWeb && Platform.isIOS) {
        edittedImagePath = await saveWidgetAsImageIOS();
      } else {
        edittedImagePath = await saveWidgetAsImage();
      }

      if (edittedImagePath == null) {
        CommonService.showError("Error in saving image");
        return;
      }
      final Map<String, dynamic> formData = {
        "title": titleController.text,
        "description": descriptionController.text,
        "targetAmount": int.tryParse(totalAmountController.text),
        "scheduledAt": scheduledAt.value!.toUtc().toIso8601String(),
        "heading1Text": heading1Text.value,
        "heading1Font": heading1Font.value,
        "heading1Color":
            '#${heading1Color.value.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        "heading2Text": heading2Text.value,
        "heading2Font": heading2Font.value,
        "heading2Color":
            '#${heading2Color.value.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        "bannerLineText": bannerLineText.value,
        "bannerLineFont": bannerLineFont.value,
        "bannerLineColor":
            '#${bannerLineColor.value.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        "bannerBackgroundColor":
            '#${bannerBackgroundColor.value.value.toRadixString(16).padLeft(8, '0').substring(2)}',
        "guests": invitedUserIds,
      };

      if (selectedImage.value != null) {
        formData['bannerImage'] = File(edittedImagePath);
      }
      if (proofImages.isNotEmpty) {
        formData["proofImages"] = proofImages;
      }
      log("Form data is $formData");

      log("Invited user ids are $invitedUserIds");
      final response = await ApiClient()
          .postFormData(ApiEndPoints.podcast, formData, requestMethod: "POST");
      getAllPodCast();
      log("Response for the create pod cast is $response");
      Get.find<LoadingController>().hide();
      Get.back();
      Get.back();
    } catch (e) {
      log("Error is $e");
      Get.find<LoadingController>().hide();
    }
  }

  Future<void> getAllPodCast() async {
    try {
      podcasts.clear();
      isPodcastLoading.value = true;
      final response = await ApiClient().get(ApiEndPoints.podcast);
      if (response != null && response['podcasts'] != null) {
        List<dynamic> list = response['podcasts'];
        podcasts.value = list.map((e) => Podcast.fromJson(e)).toList();
        log("Fetched ${podcasts.length} podcasts.");
      } else {
        log("Podcast API returned no hosted podcasts.");
      }
    } catch (e) {
      log("Error is $e");
    } finally {
      isPodcastLoading.value = false;
    }
  }

  Future<void> _loadFollowers() async {
    try {
      invitedUserLoading.value = true;
      log("🔄 Loading users from API...");
      
      // First try to get current user's profile to access followers/following
      try {
        log("🔄 Trying to get current user profile...");
        final profileResponse = await ApiClient().get("users/profile");
        log("📋 Profile response: $profileResponse");
        
        if (profileResponse != null && profileResponse['user'] != null) {
          final userData = profileResponse['user'];
          final followers = userData['followers'] as List? ?? [];
          final following = userData['following'] as List? ?? [];
          
          log("👥 Found ${followers.length} followers and ${following.length} following");
          
          // Combine followers and following, remove duplicates
          final allUsers = <Map<String, dynamic>>[];
          final userIds = <String>{};
          
          // Add followers
          for (final follower in followers) {
            if (follower is Map<String, dynamic>) {
              final userId = follower['_id']?.toString() ?? follower['id']?.toString();
              if (userId != null && !userIds.contains(userId)) {
                userIds.add(userId);
                allUsers.add({
                  'id': userId,
                  'name': follower['name']?.toString() ?? follower['username']?.toString() ?? 'Unknown User',
                  'avatar': follower['profilePic']?.toString() ?? follower['avatar']?.toString() ?? AppImages.profile,
                  'location': follower['bio']?.toString() ?? follower['description']?.toString() ?? follower['location']?.toString() ?? 'No bio available',
                });
              }
            }
          }
          
          // Add following
          for (final followingUser in following) {
            if (followingUser is Map<String, dynamic>) {
              final userId = followingUser['_id']?.toString() ?? followingUser['id']?.toString();
              if (userId != null && !userIds.contains(userId)) {
                userIds.add(userId);
                allUsers.add({
                  'id': userId,
                  'name': followingUser['name']?.toString() ?? followingUser['username']?.toString() ?? 'Unknown User',
                  'avatar': followingUser['profilePic']?.toString() ?? followingUser['avatar']?.toString() ?? AppImages.profile,
                  'location': followingUser['bio']?.toString() ?? followingUser['description']?.toString() ?? followingUser['location']?.toString() ?? 'No bio available',
                });
              }
            }
          }
          
          if (allUsers.isNotEmpty) {
            usersList.value = allUsers;
            filteredUsers.value = usersList;
            log("✅ Successfully loaded ${usersList.length} users from profile data");
            return;
          }
        }
      } catch (e) {
        log("❌ Failed to load from profile: $e");
      }
      
      // Fallback: Try the allUsers endpoint
      try {
        log("🔄 Trying allUsers endpoint...");
        final response = await ApiClient().get(ApiEndPoints.allUsers);
        log("📋 AllUsers response: $response");
        
        if (response != null) {
          List<dynamic>? rawUsers;
          
          if (response is List && response.isNotEmpty) {
            rawUsers = response;
            log("✅ Found users as direct list");
          } else if (response['users'] is List && (response['users'] as List).isNotEmpty) {
            rawUsers = response['users'] as List;
            log("✅ Found users in 'users' key");
          } else if (response['data'] is List && (response['data'] as List).isNotEmpty) {
            rawUsers = response['data'] as List;
            log("✅ Found users in 'data' key");
          }
          
           if (rawUsers != null && rawUsers.isNotEmpty) {
             usersList.value = rawUsers.map((user) {
               final userId = user['_id']?.toString() ?? user['id']?.toString() ?? "unknown_id";
               final userName = user['name']?.toString() ?? user['username']?.toString() ?? 'Unknown User';
               final userBio = user['bio']?.toString() ?? user['description']?.toString() ?? user['location']?.toString() ?? 'No bio available';
               
               // Keep the original user data structure including pets
               return {
                 'id': userId,
                 'name': userName,
                 'profilePic': user['profilePic']?.toString() ?? '',
                 'avatar': user['avatar']?.toString() ?? '',
                 'bio': user['bio']?.toString() ?? '',
                 'pets': user['pets'] ?? [],
                 'location': userBio,
               };
             }).toList();

            filteredUsers.value = usersList;
            log("✅ Successfully loaded ${usersList.length} users from allUsers endpoint");
            return;
          }
        }
      } catch (e) {
        log("❌ AllUsers endpoint failed: $e");
      }
      
      // Final fallback: Use dummy data
      log("❌ No users found from any source, using fallback data");
      usersList.value = _createFallbackUsers();
      filteredUsers.value = usersList;
      
    } catch (e) {
      log('❌ Error loading followers: $e');
      usersList.value = [];
      filteredUsers.value = [];
    } finally {
      invitedUserLoading.value = false;
    }
  }

  void toggleInvite(String userId) {
    if (invitedUserIds.contains(userId)) {
      invitedUserIds.remove(userId);
    } else {
      invitedUserIds.add(userId);
    }
  }

  void onSearchChanged(String query) {
    log("🔍 Search query: '$query'");
    log("📋 Total users available: ${usersList.length}");
    
    if (query.isEmpty) {
      filteredUsers.value = usersList;
      log("✅ Showing all ${usersList.length} users");
      return;
    }

    final filtered = usersList
        .where((user) {
          final name = user['name']?.toString().toLowerCase() ?? '';
          final location = user['location']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          
          final nameMatch = name.contains(searchQuery);
          final locationMatch = location.contains(searchQuery);
          
          if (nameMatch || locationMatch) {
            log("✅ User '${user['name']}' matches search '$query'");
          }
          
          return nameMatch || locationMatch;
        })
        .toList();
    
    filteredUsers.value = filtered;
    log("🔍 Search results: ${filtered.length} users found for '$query'");
  }

  Future<void> inviteFollower(Map<String, dynamic> follower) async {
    try {
      // TODO: Implement invite logic
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      Get.snackbar(
        'Success',
        'Invitation sent to ${follower['name']}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      log('Error inviting follower: $e');
      Get.snackbar(
        'Error',
        'Failed to send invitation. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadFollowers();
    getAllPodCast();
  }

  // Public method to refresh users data
  Future<void> refreshUsers() async {
    await _loadFollowers();
  }

  // Method to force load fallback users for testing
  void loadFallbackUsers() {
    log("🔄 Loading fallback users for testing");
    usersList.value = _createFallbackUsers();
    filteredUsers.value = usersList;
    log("✅ Loaded ${usersList.length} fallback users");
  }

  // Method to load users from current user's network (followers + following)
  Future<void> loadUsersFromNetwork() async {
    try {
      invitedUserLoading.value = true;
      log("🔄 Loading users from current user's network...");
      
      final profileResponse = await ApiClient().get("users/profile");
      log("📋 Profile response: $profileResponse");
      
      if (profileResponse != null && profileResponse['user'] != null) {
        final userData = profileResponse['user'];
        final followers = userData['followers'] as List? ?? [];
        final following = userData['following'] as List? ?? [];
        
        log("👥 Found ${followers.length} followers and ${following.length} following");
        
        // Combine followers and following, remove duplicates
        final allUsers = <Map<String, dynamic>>[];
        final userIds = <String>{};
        
        // Add followers
        for (final follower in followers) {
          if (follower is Map<String, dynamic>) {
            final userId = follower['_id']?.toString() ?? follower['id']?.toString();
            if (userId != null && !userIds.contains(userId)) {
              userIds.add(userId);
              allUsers.add({
                'id': userId,
                'name': follower['name']?.toString() ?? follower['username']?.toString() ?? 'Unknown User',
                'avatar': follower['profilePic']?.toString() ?? follower['avatar']?.toString() ?? AppImages.profile,
                'location': follower['bio']?.toString() ?? follower['description']?.toString() ?? follower['location']?.toString() ?? 'No bio available',
              });
            }
          }
        }
        
        // Add following
        for (final followingUser in following) {
          if (followingUser is Map<String, dynamic>) {
            final userId = followingUser['_id']?.toString() ?? followingUser['id']?.toString();
            if (userId != null && !userIds.contains(userId)) {
              userIds.add(userId);
              allUsers.add({
                'id': userId,
                'name': followingUser['name']?.toString() ?? followingUser['username']?.toString() ?? 'Unknown User',
                'avatar': followingUser['profilePic']?.toString() ?? followingUser['avatar']?.toString() ?? AppImages.profile,
                'location': followingUser['bio']?.toString() ?? followingUser['description']?.toString() ?? followingUser['location']?.toString() ?? 'No bio available',
              });
            }
          }
        }
        
        if (allUsers.isNotEmpty) {
          usersList.value = allUsers;
          filteredUsers.value = usersList;
          log("✅ Successfully loaded ${usersList.length} users from network");
          return;
        }
      }
      
      log("❌ No users found in network, using fallback data");
      usersList.value = _createFallbackUsers();
      filteredUsers.value = usersList;
      
    } catch (e) {
      log('❌ Error loading users from network: $e');
      usersList.value = _createFallbackUsers();
      filteredUsers.value = usersList;
    } finally {
      invitedUserLoading.value = false;
    }
  }

  // Create fallback users for testing when API fails
  List<Map<String, dynamic>> _createFallbackUsers() {
    return [
      {
        'id': 'user_1',
        'name': 'Alex Johnson',
        'avatar': 'https://i.pravatar.cc/150?img=1',
        'location': 'New York, USA',
      },
      {
        'id': 'user_2',
        'name': 'Sarah Wilson',
        'avatar': 'https://i.pravatar.cc/150?img=2',
        'location': 'Los Angeles, USA',
      },
      {
        'id': 'user_3',
        'name': 'Mike Chen',
        'avatar': 'https://i.pravatar.cc/150?img=3',
        'location': 'San Francisco, USA',
      },
      {
        'id': 'user_4',
        'name': 'Emma Davis',
        'avatar': 'https://i.pravatar.cc/150?img=4',
        'location': 'Chicago, USA',
      },
      {
        'id': 'user_5',
        'name': 'David Brown',
        'avatar': 'https://i.pravatar.cc/150?img=5',
        'location': 'Miami, USA',
      },
      {
        'id': 'user_6',
        'name': 'Lisa Garcia',
        'avatar': 'https://i.pravatar.cc/150?img=6',
        'location': 'Seattle, USA',
      },
    ];
  }

  @override
  void onClose() {
    searchController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    totalAmountController.dispose();
    super.onClose();
  }
}
