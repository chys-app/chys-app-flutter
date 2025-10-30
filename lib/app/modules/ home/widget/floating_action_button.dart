import 'package:chys/app/widget/image/svg_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_image.dart';
import '../../../core/utils/app_size.dart';
import '../../../services/pet_ownership_service.dart';
import '../../map/controllers/map_controller.dart';

// Enhanced reusable button for Material icons
class IconActionButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;

  const IconActionButton({
    Key? key,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.iconColor = const Color(0xff4B164C),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: 48,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0095F6) : backgroundColor,
          shape: BoxShape.circle,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0095F6).withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Icon(
          icon,
          color: selected ? Colors.white : iconColor,
          size: 22,
        ),
      ),
    );
  }
}

// Enhanced reusable button
class SvgActionButton extends StatelessWidget {
  final String icon;
  final bool selected;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;

  const SvgActionButton({
    Key? key,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.iconColor = const Color(0xff4B164C),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: 48,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0095F6) : backgroundColor,
          shape: BoxShape.circle,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0095F6).withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: icon.toSvg(
          color: selected ? Colors.white : iconColor,
          width: 22,
          height: 22,
        ),
      ),
    );
  }
}

// Enhanced first button group widget
class UserMapButtons extends StatelessWidget {
  final MapController controller;
  final double bottom;
  final double right;

  const UserMapButtons({
    Key? key,
    required this.controller,
    this.bottom = 10,
    this.right = 14,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      right: right,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgActionButton(
              icon: AppImages.user,
              selected: controller.selectedFeature.value == 'user',
              onTap: () => controller.selectFeature('user'),
            ),
            SizedBox(height: AppSize.h2),
            SvgActionButton(
              icon: AppImages.map,
              selected: controller.selectedFeature.value == 'map',
              onTap: () => controller.selectFeature('map'),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced second button group widget
class CustomFloatingActionButton extends StatelessWidget {
  final MapController controller;
  final double bottom;
  final double right;

  const CustomFloatingActionButton({
    Key? key,
    required this.controller,
    this.bottom = 24,
    this.right = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      right: right,
      child: Obx(() {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgActionButton(
                icon: AppImages.add,
                selected: controller.selectedFeature.value == 'add',
                onTap: () {
                  final petService = PetOwnershipService.instance;
                  if (petService.canCreatePosts) {
                    controller.selectFeature('add');
                  } else {
                    petService.showPostRestriction();
                  }
                },
              ),
              const SizedBox(height: 16),
              SvgActionButton(
                icon: AppImages.podcast,
                selected: controller.selectedFeature.value == 'podcast',
                onTap: () {
                  final petService = PetOwnershipService.instance;
                  if (petService.canCreatePodcasts) {
                    controller.selectFeature('podcast');
                  } else {
                   petService.showPodcastRestriction();
                  }
                },
              ),
              const SizedBox(height: 16),
              SvgActionButton(
                icon: AppImages.chat,
                selected: controller.selectedFeature.value == 'chat',
                onTap: () => controller.selectFeature('chat'),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0095F6),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0095F6).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  "19.14 ▮ 19.14",
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// Enhanced bottom navigation bar
class BottomNavigationBarWidget extends StatelessWidget {
  final MapController controller;

  const BottomNavigationBarWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgActionButton(
              icon: AppImages.user,
              selected: controller.selectedFeature.value == 'user',
              onTap: () => controller.selectFeature('user'),
            ),
            SvgActionButton(
              icon: AppImages.map,
              selected: controller.selectedFeature.value == 'map',
              onTap: () => controller.selectFeature('map'),
            ),
            if (controller.isBusinessUser.value)
              SvgActionButton(
                icon: AppImages.bankInfo,
                selected: controller.selectedFeature.value == 'business',
                onTap: () => controller.selectFeature('business'),
              ),
            SvgActionButton(
              icon: AppImages.chat,
              selected: controller.selectedFeature.value == 'chat',
              onTap: () => controller.selectFeature('chat'),
            ),
            if (!controller.isBusinessUser.value)
              SvgActionButton(
                icon: AppImages.add,
                selected: controller.selectedFeature.value == 'add',
                onTap: () {
                  final petService = PetOwnershipService.instance;
                  if (petService.canCreatePosts) {
                    controller.selectFeature('add');
                  } else {
                    petService.showPostRestriction();
                  }
                },
              ),
            IconActionButton(
              icon: Icons.search,
              selected: controller.selectedFeature.value == 'search',
              onTap: () => controller.selectFeature('search'),
            ),
            SvgActionButton(
              icon: AppImages.podcast,
              selected: controller.selectedFeature.value == 'podcast',
              onTap: () {
                final petService = PetOwnershipService.instance;
                if (petService.canCreatePodcasts) {
                  controller.selectFeature('podcast');
                } else {
                  petService.showPodcastRestriction();
                }
              },
            ),
            IconActionButton(
              icon: Icons.volunteer_activism_outlined,
              selected: controller.selectedFeature.value == 'donate',
              onTap: () => controller.selectFeature('donate'),
            ),
          ],
        ),
      );
    });
  }
}
