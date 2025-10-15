import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:chys/app/core/controllers/loading_controller.dart';
import 'package:chys/app/modules/podcast/controllers/create_podcast_controller.dart';
import 'package:chys/app/services/common_service.dart';
import 'package:chys/app/services/http_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/const/app_colors.dart';
import '../../map/controllers/map_controller.dart';

class RecentDonation {
  final String userName;
  final int amount;
  final DateTime createdAt;

  RecentDonation(
      {required this.userName, required this.amount, required this.createdAt});

  factory RecentDonation.fromJson(Map<String, dynamic> json) {
    return RecentDonation(
      userName: json['user']?['name'] ?? 'Unknown',
      amount: json['amount'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class PodcastController extends GetxController {
  RxSet<int> mutedUsers = <int>{}.obs;
  RxSet<int> videoMutedUsers = <int>{}.obs; // Track video mute status
  final String appId = 'bd4ff676cee84db68736ae01e6815373';
  String channelName = '';
  String token = '';
  String podCastId = '';
  RxInt uid = 0.obs;
  RxnInt adminUid = RxnInt();
  late RtcEngine engine;
  RxBool joined = false.obs;
  RxSet<int> participants = <int>{}.obs;
  RxSet<int> speakingUsers = <int>{}.obs;
  RxBool isInitialized = false.obs;
  RxBool localVideoEnabled = true.obs; // Track local video state

  // Add this for large video view selection
  RxnInt? selectedLargeViewUserId = RxnInt();

  // Fundraising state management
  final RxInt selectedFundraisingAmount = RxInt(0);
  final RxInt targetFundraisingAmount = RxInt(0);
  final RxInt totalAmount = RxInt(0);
  final TextEditingController fundraisingAmountController =
      TextEditingController();
  final List<int> predefinedAmounts = [10, 20, 50, 100, 500, 1000];

  final RxList<RecentDonation> recentDonations = <RecentDonation>[].obs;

  void resetFundraisingState() {
    selectedFundraisingAmount.value = 0;
    fundraisingAmountController.clear();
  }

  bool get isAdmin => uid.value == adminUid.value;

  Future<void> donateNow() async {
    try {
      Get.find<LoadingController>().show();
      final response = await ApiClient().post(
        "${ApiEndPoints.fundRaise}/podcast/$podCastId",
        {
          "amount": selectedFundraisingAmount.value,
        },
      );
      fetchRecentDonations();
      log("Response for donation is $response");
      Get.find<LoadingController>().hide();
    } catch (e) {
      Get.find<LoadingController>().hide();
      log("Error is $e");
    }
  }

  Future<void> fetchRecentDonations() async {
    try {
      final response = await ApiClient().get(
        "${ApiEndPoints.getFunds}/$podCastId",
      );
      log("Response for getting recent donation  is $response");

      if (response != null && response['funds'] is List) {
        totalAmount.value = response["totalAmount"];
        targetFundraisingAmount.value = response["targetAmount"];
        recentDonations.value = (response['funds'] as List)
            .map((e) => RecentDonation.fromJson(e))
            .toList();
      } else {
        recentDonations.clear();
      }
    } catch (e) {
      log("Error is $e");
      recentDonations.clear();
    }
  }

  void assignUserId(String newUserId) {
    try {
      int userId = newUserId.hashCode & 0xFFFFFFFF;
      log("Updated user id is $userId");
      uid.value = userId;
    } catch (e) {
      log("Error getting profile ID, using fallback: $e");
      uid.value = DateTime.now().millisecondsSinceEpoch % 1000000;
    }
  }

  Future<bool> _requestPermissions() async {
    log("🎙️ Requesting permissions...");

    // Check current permission status first
    PermissionStatus microphoneStatus = await Permission.microphone.status;
    PermissionStatus cameraStatus = await Permission.camera.status;

    log("Current microphone status: $microphoneStatus");
    log("Current camera status: $cameraStatus");

    // If permissions are permanently denied, guide user to settings
    if (microphoneStatus == PermissionStatus.permanentlyDenied ||
        cameraStatus == PermissionStatus.permanentlyDenied) {
      _showPermissionSettingsDialog();
      return false;
    }

    // Request permissions
    Map<Permission, PermissionStatus> permissions = await [
      Permission.microphone,
      Permission.camera,
    ].request();

    log("Permission results: $permissions");

    // Check if all permissions were granted
    bool allGranted = permissions.values
        .every((status) => status == PermissionStatus.granted);

    if (!allGranted) {
      // Show specific error for denied permissions
      List<String> deniedPermissions = [];
      if (permissions[Permission.microphone] != PermissionStatus.granted) {
        deniedPermissions.add('Microphone');
      }
      if (permissions[Permission.camera] != PermissionStatus.granted) {
        deniedPermissions.add('Camera');
      }

      String deniedList = deniedPermissions.join(' and ');
      Get.snackbar(
        "Permission Required",
        "$deniedList access is required to join the podcast. Please grant permissions in Settings.",
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
      );

      // If any permission is permanently denied, show settings dialog
      if (permissions.values
          .any((status) => status == PermissionStatus.permanentlyDenied)) {
        _showPermissionSettingsDialog();
      }

      return false;
    }

    log("✅ All permissions granted");
    return true;
  }

  void _showPermissionSettingsDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text("Permissions Required"),
        content: const Text(
          "Microphone and camera permissions are required to join the podcast. "
          "Please enable them in your device settings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  Future<void> _initAgora() async {
    log("🎙️ _initAgora() called");
    try {
      // Request permissions first
      bool permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        log("🚫 Permissions not granted, cannot initialize Agora");
        return;
      }

      engine = createAgoraRtcEngine();
      log("🛠️ Agora engine created");
      await engine.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType
              .channelProfileCommunication, // Suitable for video
        ),
      );

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection conn, int elapsed) async {
            log("✅ Successfully joined channel '${conn.channelId}' as UID ${conn.localUid} $isAdmin");
            joined.value = true;
            participants.add(uid.value);
            await engine.muteLocalAudioStream(false);
            await engine.muteLocalVideoStream(false); // Enable local video
            log("🎤 Audio and 📹 Video enabled.");
          },
          onUserJoined: (conn, remoteUid, _) {
            log("👤 User joined: $remoteUid");
            participants.add(remoteUid);
          },
          onUserOffline: (conn, remoteUid, reason) {
            log("🚪 User offline: $remoteUid, Reason: $reason");
            participants.remove(remoteUid);
            speakingUsers.remove(remoteUid);
            videoMutedUsers.remove(remoteUid);
            if (remoteUid == adminUid.value && !isAdmin) {
              CommonService.showError("The host has left, ended the podcast");
              leaveChannel();
            }
          },
          onError: (err, msg) {
            log("❌ Agora error: $err - $msg");
            Get.snackbar("Connection Error", "Failed to connect: $msg");
          },
          onAudioVolumeIndication: (connection, speakers, _, __) {
            for (var speaker in speakers) {
              if (speaker.volume! > 10) {
                speakingUsers.add(speaker.uid!);
              } else {
                speakingUsers.remove(speaker.uid);
              }
            }
          },
          onUserMuteVideo: (conn, remoteUid, muted) {
            log("📹 User $remoteUid video muted: $muted");
            if (muted) {
              videoMutedUsers.add(remoteUid);
            } else {
              videoMutedUsers.remove(remoteUid);
            }
          },
        ),
      );

      await engine.enableVideo(); // Enable video
      await engine.enableAudio();
      await engine.enableLocalAudio(true);
      await engine
          .setChannelProfile(ChannelProfileType.channelProfileCommunication);
      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await engine.enableAudioVolumeIndication(
          interval: 200, smooth: 3, reportVad: true);
      isInitialized.value = true;
      log("✅ Agora initialized successfully");
    } catch (e, stackTrace) {
      log("❌ Error initializing Agora: $e\nStackTrace: $stackTrace");
      Get.snackbar("Initialization Error", "Failed to initialize engine");
    }
  }

  Future<void> joinChannel() async {
    log("🚪 joinChannel() called");
    try {
      if (joined.value) return;

      Get.find<LoadingController>().show();

      // Check permissions before initializing Agora
      if (!isInitialized.value) {
        bool permissionsGranted = await _requestPermissions();
        if (!permissionsGranted) {
          Get.find<LoadingController>().hide();
          log("🚫 Cannot join channel - permissions not granted");
          return;
        }

        await _initAgora();
        if (!isInitialized.value) {
          Get.find<LoadingController>().hide();
          return;
        }
      }

      final response =
          await ApiClient().get("${ApiEndPoints.podcast}/$podCastId/token");
      uid.value = response["uid"];
      adminUid.value = response["hostNumericUid"];
      log("Admin uid is ${response["hostNumericUid"]} and id is $adminUid");

      token = response["token"];
      channelName = response["channelName"];

      await engine.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid.value,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          audienceLatencyLevel:
              AudienceLatencyLevelType.audienceLatencyLevelLowLatency,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishMicrophoneTrack: true,
          publishCameraTrack: true, // Enable video publishing
          enableAudioRecordingOrPlayout: true,
        ),
      );

      await engine.muteLocalAudioStream(false);
      await engine.muteLocalVideoStream(false);
      Get.find<LoadingController>().hide();
    } catch (e) {
      Get.find<LoadingController>().hide();
      log("❌ Error joining channel: $e");
      Get.snackbar("Join Error", "Failed to join podcast room");
    }
  }

  Future<void> toggleMute(int userId) async {
    if (!isAdmin) return;
    try {
      if (mutedUsers.contains(userId)) {
        await engine.muteRemoteAudioStream(uid: userId, mute: false);
        mutedUsers.remove(userId);
        Get.snackbar("User Unmuted", "User can now speak",
            backgroundColor: AppColors.primary);
      } else {
        await engine.muteRemoteAudioStream(uid: userId, mute: true);
        mutedUsers.add(userId);
        speakingUsers.remove(userId);
        Get.snackbar("User Muted", "User has been muted",
            backgroundColor: AppColors.error);
      }
    } catch (e) {
      log("❌ Error toggling mute: $e");
      Get.snackbar("Mute Error", "Failed to toggle mute status",
          backgroundColor: AppColors.error);
    }
  }

  Future<void> toggleVideoMute(int userId) async {
    if (!isAdmin) return;
    try {
      if (videoMutedUsers.contains(userId)) {
        await engine.muteRemoteVideoStream(uid: userId, mute: false);
        videoMutedUsers.remove(userId);
        Get.snackbar("Video Unmuted", "User video enabled",
            backgroundColor: AppColors.primary);
      } else {
        await engine.muteRemoteVideoStream(uid: userId, mute: true);
        videoMutedUsers.add(userId);
        Get.snackbar("Video Muted", "User video disabled",
            backgroundColor: AppColors.error);
      }
    } catch (e) {
      log("❌ Error toggling video mute: $e");
      Get.snackbar("Video Mute Error", "Failed to toggle video status",
          backgroundColor: AppColors.error);
    }
  }

  Future<void> endPodCast() async {
    try {
      Get.find<LoadingController>().show();

      final response = await ApiClient().post(
        "${ApiEndPoints.podcast}/$podCastId/end",
        {},
      );

      log("Response for the podcast ending is $response");
      Get.find<LoadingController>().hide();

      // Instead of `Get.back()` followed by `Get.offAll`, do this:
    } catch (e) {
      log("Error ending podcast: $e");
      Get.find<LoadingController>().hide();
    }
  }

  Future<void> toggleLocalVideo() async {
    try {
      localVideoEnabled.value = !localVideoEnabled.value;
      await engine.muteLocalVideoStream(!localVideoEnabled.value);
      log("📹 Local video ${localVideoEnabled.value ? 'enabled' : 'disabled'}");
    } catch (e) {
      log("❌ Error toggling local video: $e");
      Get.snackbar("Error", "Failed to toggle video");
    }
  }

  Future<void> leaveChannel() async {
    log("🚪 leaveChannel() called");
    try {
      await engine.leaveChannel();
      if (isAdmin) await endPodCast();
      Get.find<LoadingController>().show();
      await Future.delayed(const Duration(milliseconds: 300));
      await Get.find<CreatePodCastController>().getAllPodCast();
      Get.find<LoadingController>().hide();
      Get.find<MapController>().selectFeature("user");
      joined.value = false;
      participants.clear();
      speakingUsers.clear();
      videoMutedUsers.clear();
      localVideoEnabled.value = true;
      log("✅ Left the channel successfully");
    } catch (e) {
      log("❌ Error leaving channel: $e");
      Get.find<LoadingController>().hide();
    }
  }

  bool isSpeaking(int userId) => speakingUsers.contains(userId);
  bool isMuted(int userId) => mutedUsers.contains(userId);
  bool isVideoMuted(int userId) => videoMutedUsers.contains(userId);

  Future<void> switchCamera() async {
    try {
      await engine.switchCamera();
      log('🔄 Camera switched');
    } catch (e) {
      log('❌ Error switching camera: $e');
      Get.snackbar('Error', 'Failed to switch camera');
    }
  }


  // Method to handle permission revocation during runtime
  Future<void> handlePermissionRevocation() async {
    log("🔄 Checking for permission revocation...");
    bool permissionsAvailable = await checkPermissionsAvailable();

    if (!permissionsAvailable) {
      log("🚫 Permissions revoked, leaving channel");
      if (joined.value) {
        await leaveChannel();
      }

      Get.snackbar(
        "Permissions Required",
        "Microphone and camera permissions are required. Please grant them in Settings.",
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
      );

      _showPermissionSettingsDialog();
    }
  }

  @override
  void onClose() {
    if (joined.value) leaveChannel();
    if (isInitialized.value) {
      engine.release();
    }
    super.onClose();
  }

  // Method to pre-request permissions (call this before navigating to podcast screen)
  Future<bool> preRequestPermissions() async {
    log("🎙️ Pre-requesting permissions...");

    // Check current status
    PermissionStatus microphoneStatus = await Permission.microphone.status;
    PermissionStatus cameraStatus = await Permission.camera.status;

    // If already granted, return true
    if (microphoneStatus == PermissionStatus.granted &&
        cameraStatus == PermissionStatus.granted) {
      log("✅ Permissions already granted");
      return true;
    }

    // If permanently denied, show settings dialog
    if (microphoneStatus == PermissionStatus.permanentlyDenied ||
        cameraStatus == PermissionStatus.permanentlyDenied) {
      _showPermissionSettingsDialog();
      return false;
    }

    // Request permissions
    return await _requestPermissions();
  }

  // Add a method to check if permissions are available
  Future<bool> checkPermissionsAvailable() async {
    PermissionStatus microphoneStatus = await Permission.microphone.status;
    PermissionStatus cameraStatus = await Permission.camera.status;

    return microphoneStatus == PermissionStatus.granted &&
        cameraStatus == PermissionStatus.granted;
  }
}
