import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:chys/app/core/controllers/loading_controller.dart';
import 'package:chys/app/data/models/podcast_model.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
 
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/const/app_colors.dart';
import '../../../services/common_service.dart';
import '../../../services/payment_services.dart';
import '../../../services/short_message_utils.dart';
import '../../../widget/common/podcast_banner_card.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../signup/widgets/custom_text_field.dart';
import '../controllers/podcast_controller.dart';

class PodcastView extends StatelessWidget {
  const PodcastView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PodcastController());
    final argument = Get.arguments as Podcast;
    final profileController = Get.find<ProfileController>();

    final isHost = argument.host.id == profileController.profile.value?.id;
    final scheduledAt = argument.scheduledAt?.toUtc();
    final isScheduledInFuture =
        scheduledAt != null && scheduledAt.isAfter(DateTime.now().toUtc());

    // Add RxnInt for selected large view user
    controller.selectedLargeViewUserId ??= RxnInt();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final canJoin = CommonService.canJoinPodcast(
        hostId: argument.host.id,
        status: argument.status,
        scheduledAt: argument.scheduledAt,
      );
      if (canJoin && !controller.joined.value) {
        await controller.joinChannel();
      }
    });

    void _showExitDialog() {
      final isAdmin = controller.isAdmin;
      final joined = controller.joined.value;
      if (!joined) {
        Get.back();
        return;
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.exit_to_app, color: AppColors.error, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                "Exit Podcast",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Text(
            isAdmin
                ? "You are the host. If you exit, the podcast will be ended for everyone. Are you sure?"
                : "Are you sure you want to leave the podcast?",
            style: GoogleFonts.inter(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.exit_to_app, size: 18),
              label: Text("Exit", style: GoogleFonts.inter()),
              onPressed: () async => await controller.leaveChannel(),
            ),
          ],
        ),
      );
    }

    String encodePodcast(Podcast podcast) {
      final jsonStr = jsonEncode(podcast.toJson());
      final base64Str = base64UrlEncode(utf8.encode(jsonStr));
      return base64Str;
    }

    void _sharePodcast(Podcast podcast) async {
      try {
        Get.find<LoadingController>().show();

        final String title = podcast.title;
        final String description = podcast.description;
        final String banner = podcast.bannerImage ?? '';

        // 🔐 Encode the podcast
        final String encodedPodcast = encodePodcast(podcast);

        // 🔗 Generate Firebase Dynamic Link
        final DynamicLinkParameters parameters = DynamicLinkParameters(
          uriPrefix: 'https://ocdcleaner.page.link',
          link: Uri.parse(
              'https://ocdcleaner.page.link/podcast?data=$encodedPodcast'),
          androidParameters: const AndroidParameters(
            packageName: 'com.example.chys',
          ),
          iosParameters: const IOSParameters(
            bundleId: 'com.app.chys',
          ),
          socialMetaTagParameters: SocialMetaTagParameters(
            title: title,
            description: description,
            imageUrl: banner.isNotEmpty ? Uri.parse(banner) : null,
          ),
        );

        final ShortDynamicLink shortLink =
            await FirebaseDynamicLinks.instance.buildShortLink(parameters);
        final String podcastUrl = shortLink.shortUrl.toString();

        // 📦 Create share text
        final String shareText = '''
🎙️ $title

$description

Join this podcast on CHYS:
$podcastUrl
''';

        XFile? previewFile;

        // 🖼️ Download image if available
        if (banner.isNotEmpty) {
          final response = await http.get(Uri.parse(banner));
          if (response.statusCode == 200) {
            final bytes = response.bodyBytes;
            final tempDir = await getTemporaryDirectory();
            final file = File('${tempDir.path}/shared_podcast.jpg');
            await file.writeAsBytes(bytes);
            previewFile = XFile(file.path);
          } else {
            log("Failed to download banner: ${response.statusCode}");
          }
        }

        // 📤 Share
        await Share.share(
          shareText,
          subject: title,
        );

        Get.find<LoadingController>().hide();
      } catch (e, stackTrace) {
        log("Error sharing podcast: $e");
        log("StackTrace: $stackTrace");
        Get.find<LoadingController>().hide();
        ShortMessageUtils.showError("Failed to share podcast");
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (canPop, result) {
        if (controller.joined.value) {
          _showExitDialog();
        } else {
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(controller, _showExitDialog, () {
          _sharePodcast(argument);
        }),
        body: Obx(() {
          if (!controller.joined.value) {
            return _buildJoinScreen(controller, isHost, scheduledAt);
          }
          return _buildPodcastRoom(controller, argument);
        }),
        floatingActionButton: _buildFloatingControls(controller),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      PodcastController controller, VoidCallback onExit, VoidCallback onShare) {
    return AppBar(
      leading: Container(),
      backgroundColor: AppColors.background,
      centerTitle: true,
      elevation: 0,
      shadowColor: Colors.transparent,
      title: Column(
        children: [
          Text(
            'Live Podcast',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Obx(() {
            if (!controller.joined.value) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0095F6), Color(0xFF00C851)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0095F6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${controller.participants.length} listening',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.share, color: Color(0xFF0095F6), size: 20),
          ),
          tooltip: 'Share Podcast',
          onPressed: onShare,
        ),
        Obx(() {
          if (!controller.joined.value) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              tooltip: 'Exit Podcast',
              onPressed: onExit,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildJoinScreen(
      PodcastController controller, bool isHost, DateTime? scheduledAt) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.secondary,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0095F6), Color(0xFF00C851)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0095F6).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Join the Conversation',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Connect with fellow pet lovers in this live audio experience',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (isHost && scheduledAt != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.main_black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0095F6), Color(0xFF00C851)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.schedule,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Scheduled Start',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        DateFormat.yMMMEd()
                            .add_jm()
                            .format(scheduledAt.toLocal()),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CommonService.formatRemainingTime(scheduledAt),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF00C851),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodcastRoom(PodcastController controller, Podcast model) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Podcast Banner
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.main_black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: PodcastBannerCard(podcast: model),
            ),
          ),
          const SizedBox(height: 24),

          // Live status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0095F6), Color(0xFF00C851)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0095F6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.people,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${controller.participants.length} listening',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Large video view section
          Obx(() {
            final selectedId = controller.selectedLargeViewUserId?.value;
            if (selectedId == null) return const SizedBox.shrink();
            final speaking = controller.isSpeaking(selectedId);
            final isMuted = controller.isMuted(selectedId);
            final isVideoMuted = controller.isVideoMuted(selectedId);
            return Column(
              children: [
                _buildVideoTile(
                  selectedId,
                  speaking,
                  isMuted,
                  isVideoMuted,
                  controller: controller,
                  isLarge: true,
                  onTap: () {
                    controller.selectedLargeViewUserId?.value = null;
                  },
                ),
                const SizedBox(height: 20),
              ],
            );
          }),

          // Participants section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0095F6), Color(0xFF00C851)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.people_alt,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Participants',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0095F6), Color(0xFF00C851)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${controller.participants.length}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Participants grid
          controller.participants.isEmpty
              ? _buildEmptyState('No participants yet')
              : GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                  physics: const NeverScrollableScrollPhysics(),
                  children: (controller.participants.toList()
                        ..sort((a, b) => a == controller.uid.value
                            ? -1
                            : b == controller.uid.value
                                ? 1
                                : 0))
                      .map((userId) {
                    final speaking = controller.isSpeaking(userId);
                    final isMuted = controller.isMuted(userId);
                    final isVideoMuted = controller.isVideoMuted(userId);
                    return GestureDetector(
                      onTap: () {
                        if (controller.selectedLargeViewUserId?.value ==
                            userId) {
                          controller.selectedLargeViewUserId?.value = null;
                        } else {
                          controller.selectedLargeViewUserId?.value = userId;
                        }
                      },
                      child: _buildVideoTile(
                        userId,
                        speaking,
                        isMuted,
                        isVideoMuted,
                        controller: controller,
                        isLarge: false,
                      ),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 24),

          // Fundraising button
          Center(
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0095F6), Color(0xFF00C851)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0095F6).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.favorite, color: Colors.white),
                label: Text(
                  'Support the Podcast',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => _showFundraisingSheet(controller),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.main_black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.people_outline,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Participants will appear here once they join',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoTile(int userId, bool speaking, bool isMuted, bool isVideoMuted,
      {required PodcastController controller,
      bool isLarge = false,
      VoidCallback? onTap}) {
    final isCurrentUser = userId == controller.uid.value;
    final isLocalInLargeView = isCurrentUser &&
        controller.selectedLargeViewUserId?.value == controller.uid.value;

    return Container(
      height: isLarge ? 360 : null,
      width: isLarge ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isLarge ? 24 : 20),
        border: Border.all(
          color: speaking
              ? const Color(0xFF00C851)
              : (isCurrentUser ? const Color(0xFF0095F6) : AppColors.border),
          width: speaking ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: speaking
                ? const Color(0xFF00C851).withOpacity(0.3)
                : AppColors.main_black.withOpacity(0.1),
            blurRadius: isLarge ? 20 : 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isLarge ? 24 : 20),
        child: Stack(
          children: [
            // Video Feed
            if (isVideoMuted ||
                (isCurrentUser && !controller.localVideoEnabled.value))
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.main_black,
                      AppColors.Gunmetal,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0095F6), Color(0xFF00C851)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: isLarge ? 60 : 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isCurrentUser ? 'You' : 'User $userId',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: isLarge ? 18 : 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (isCurrentUser && !isLarge && isLocalInLargeView)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.Cultured,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam,
                        size: 40,
                        color: AppColors.Slate_Gray,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'In large view',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: controller.engine,
                  canvas: VideoCanvas(
                    uid: isCurrentUser ? 0 : userId,
                    renderMode: RenderModeType.renderModeFit,
                  ),
                ),
              ),

            // Gradient overlay for better text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(isLarge ? 24 : 20),
                  ),
                ),
              ),
            ),

            // User info overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrentUser
                                ? const Color(0xFF0095F6)
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isCurrentUser ? 'You' : 'User $userId',
                            style: GoogleFonts.inter(
                              color: isCurrentUser ? Colors.white : Colors.white,
                              fontSize: isLarge ? 14 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (speaking) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0095F6), Color(0xFF00C851)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Speaking',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Status indicators
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                children: [
                  if (isMuted)
                    Container(
                      width: isLarge ? 32 : 24,
                      height: isLarge ? 32 : 24,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.mic_off,
                        size: isLarge ? 18 : 14,
                        color: Colors.white,
                      ),
                    ),
                  if (isMuted) const SizedBox(width: 8),
                  if (isVideoMuted ||
                      (isCurrentUser && !controller.localVideoEnabled.value))
                    Container(
                      width: isLarge ? 32 : 24,
                      height: isLarge ? 32 : 24,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.videocam_off,
                        size: isLarge ? 18 : 14,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),

            // Admin controls
            Obx(() {
              if (controller.isAdmin && !isCurrentUser) {
                return Positioned(
                  top: 12,
                  left: 12,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            isMuted ? Icons.mic : Icons.mic_off,
                            color: isMuted ? Colors.red : Colors.white,
                            size: isLarge ? 20 : 16,
                          ),
                          onPressed: () => controller.toggleMute(userId),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            isVideoMuted ? Icons.videocam : Icons.videocam_off,
                            color: isVideoMuted ? Colors.red : Colors.white,
                            size: isLarge ? 20 : 16,
                          ),
                          onPressed: () => controller.toggleVideoMute(userId),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }),

            // Tap overlay for large view
            if (onTap != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(isLarge ? 24 : 20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingControls(PodcastController controller) {
    return Obx(() {
      if (!controller.joined.value) return const SizedBox.shrink();

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Switch camera button
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: FloatingActionButton(
              heroTag: 'switch_camera',
              mini: true,
              backgroundColor: AppColors.background,
              foregroundColor: const Color(0xFF0095F6),
              elevation: 8,
              onPressed: controller.switchCamera,
              child: const Icon(Icons.cameraswitch, size: 20),
              tooltip: 'Switch Camera',
            ),
          ),
          // Toggle video button
          FloatingActionButton(
            heroTag: 'toggle_video',
            backgroundColor: controller.localVideoEnabled.value
                ? const Color(0xFF0095F6)
                : AppColors.error,
            foregroundColor: Colors.white,
            elevation: 8,
            onPressed: controller.toggleLocalVideo,
            child: Icon(
              controller.localVideoEnabled.value
                  ? Icons.videocam
                  : Icons.videocam_off,
              size: 24,
            ),
            tooltip: controller.localVideoEnabled.value
                ? 'Turn Off Video'
                : 'Turn On Video',
          ),
        ],
      );
    });
  }

  void _showFundraisingSheet(PodcastController controller) {
    controller.fetchRecentDonations();
    controller.resetFundraisingState();

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24),
            child: Obx(
              () => SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '💚 Support the Podcast',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),

                    /// Total raised & progress
                    const SizedBox(height: 12),
                    Text(
                      'Total Raised',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        '\$${controller.totalAmount.value}',
                        key: ValueKey(controller.totalAmount.value),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          color: const Color(0xFF0095F6),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: controller.totalAmount.value /
                          controller.targetFundraisingAmount.value
                              .clamp(1, double.infinity),
                      backgroundColor: const Color(0xFF0095F6).withOpacity(0.1),
                      color: const Color(0xFF0095F6),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Goal: \$${controller.targetFundraisingAmount.value}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    /// Recent Donors
                    const SizedBox(height: 20),
                    Text(
                      '💚 Recent Donors',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      if (controller.recentDonations.isEmpty) {
                        return Text(
                          'No recent donations yet.',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        );
                      }
                      return Column(
                        children: controller.recentDonations
                            .map(
                              (donation) => Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: Icon(Icons.favorite,
                                      color: const Color(0xFF0095F6)),
                                  title: Text('Donated', style: GoogleFonts.inter()),
                                  trailing: Text(
                                    '+\$${donation.amount}',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0095F6),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    }),

                    /// Fundraising Input
                    const SizedBox(height: 28),
                    Text(
                      'Enter Amount to Support',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// Chips
                    Wrap(
                      spacing: 10,
                      children: controller.predefinedAmounts.map((amount) {
                        final isSelected =
                            controller.selectedFundraisingAmount.value ==
                                amount;
                        return ChoiceChip(
                          label: Text('\$$amount'),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0095F6),
                          labelStyle: GoogleFonts.inter(
                            color:
                                isSelected ? Colors.white : const Color(0xFF0095F6),
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: const Color(0xFF0095F6).withOpacity(0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              controller.selectedFundraisingAmount.value =
                                  amount;
                              controller.fundraisingAmountController.text =
                                  amount.toString();
                            } else {
                              controller.selectedFundraisingAmount.value = 0;
                              controller.fundraisingAmountController.clear();
                            }
                          },
                        );
                      }).toList(),
                    ),

                    /// Manual input
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: controller.fundraisingAmountController,
                      label: 'Amount (USD)',
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null &&
                            controller.predefinedAmounts.contains(parsed)) {
                          controller.selectedFundraisingAmount.value = parsed;
                        } else {
                          controller.selectedFundraisingAmount.value = 0;
                        }
                      },
                    ),

                    /// Donate Button
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0095F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Support Now',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () async {
                          final amount = controller
                              .fundraisingAmountController.text
                              .trim();
                          if (amount.isEmpty ||
                              double.tryParse(amount) == null) {
                            CommonService.showError(
                                'Please enter a valid amount');
                            return;
                          }

                          final result = await PaymentServices.stripePayment(
                            amount,
                            controller.podCastId,
                            context,
                            onSuccess: () {
                              controller.donateNow();
                              Get.back();
                            },
                          );

                          if (result) {
                            // Optional: refresh total
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
