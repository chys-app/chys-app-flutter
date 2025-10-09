import 'dart:convert';
import 'dart:developer';

import 'package:chys/app/modules/map/controllers/map_controller.dart';
import 'package:chys/app/modules/podcast/controllers/podcast_controller.dart';
import 'package:chys/app/modules/profile/controllers/profile_controller.dart';
import 'package:chys/app/modules/signup/controller/signup_controller.dart';
import 'package:chys/app/services/short_message_utils.dart';
import 'package:chys/app/services/storage_service.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../data/models/podcast_model.dart';
import '../modules/adored_posts/controller/controller.dart';
import '../routes/app_routes.dart';
import 'common_service.dart';

class FirebaseDynamicLinkService {
  static Uri? _initialLink;

  Uri? get initialLink => _initialLink;
  Podcast? decodePodcast(String base64Str) {
    try {
      final jsonStr = utf8.decode(base64Url.decode(base64Str));
      final json = jsonDecode(jsonStr);
      return Podcast.fromJson(json);
    } catch (e) {
      log("Error decoding podcast: $e");
      return null;
    }
  }

  Future<void> initDynamicLinks() async {
    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();

    if (data?.link != null) {
      _initialLink = data!.link;
      print('[FirebaseDynamicLinkService] Initial link: $_initialLink');
    }

    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      final uri = dynamicLinkData.link;
      print('[FirebaseDynamicLinkService] Live link: $uri');
      _handleIncomingLink(uri);
    }).onError((error) {
      print('[FirebaseDynamicLinkService] Error in stream: $error');
    });
  }

  void _handleIncomingLink(Uri uri) async {
    if (uri.path == '/api/users/verify-email' &&
        uri.queryParameters['token'] != null) {
      final token = uri.queryParameters['token']!;
      try {
        // Verify email using token via API
        final response = await http.get(Uri.parse(uri.toString()));

        if (response.statusCode == 200) {
          // Email verified successfully
          await StorageService.setStepDone(StorageService.signupDone);
          await StorageService.setStepDone(StorageService.editProfileDone);
          // loading.hide();

          // Put controller if needed
          Get.put(SignupController());
          Get.offAllNamed(AppRoutes.petOwnership, arguments: true);

          // Navigate to edit profile screen
          // Get.offAllNamed(AppRoutes.editProfile, arguments: true);
        } else {
          Get.offAllNamed(AppRoutes.verifyEmailView);
          ShortMessageUtils.showError("Email verification failed.");
        }
      } catch (e) {
        Get.offAllNamed(AppRoutes.verifyEmailView);
        ShortMessageUtils.showError(
            "Something went wrong during verification.");
      }
      return;
    }

    // Already existing logic:
    if (StorageService.getToken() != null) {
      _navigateFromUri(uri);
    }
  }

  void _navigateFromUri(Uri uri) {
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'post') {
      final postId = uri.pathSegments[1];
      Get.put(ProfileController());
      final controller = Get.put(AddoredPostsController(), tag: 'home');
      Get.offAllNamed(AppRoutes.postPreview, arguments: {
        'postId': postId,
        'controller': controller,
      });
    }
    
    // Handle pet profile links
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'pet') {
      final petId = uri.pathSegments[1];
      log("Navigating to pet profile with ID: $petId");
      
      // Put required controllers
      Get.put(ProfileController());
      final mapController = Get.put(MapController());
      
      // Navigate to pet detail page with pet ID
      Get.offAllNamed(AppRoutes.homeDetail, arguments: petId);
    }
    
    if (uri.path == '/podcast' && uri.queryParameters['data'] != null) {
      final encodedData = uri.queryParameters['data']!;
      final podcast = decodePodcast(encodedData);

      if (podcast != null) {
        final canJoin = CommonService.canJoinPodcast(
          hostId: podcast.host.id,
          status: podcast.status,
          scheduledAt: podcast.scheduledAt,
        );

        if (canJoin) {
          final podCastCallController = Get.put(PodcastController());
          podCastCallController.podCastId = podcast.id;
          Get.toNamed(AppRoutes.podCastView, arguments: podcast);
        } else {
          Future.microtask(
              () => Get.put(MapController()).selectFeature("user"));
        }
      } else {
        ShortMessageUtils.showError("Invalid podcast link");
        Get.offAllNamed(AppRoutes.home);
      }
    }
  }

  void handleCachedLinkAfterAuth() {
    if (_initialLink != null) {
      _navigateFromUri(_initialLink!);
      _initialLink = null;
    }
  }
}
