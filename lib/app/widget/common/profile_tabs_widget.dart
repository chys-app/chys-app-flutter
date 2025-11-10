import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileTabData {
  final IconData icon;
  final String text;

  const ProfileTabData({
    required this.icon,
    required this.text,
  });
}

class ProfileTabsWidget extends StatelessWidget {
  final TabController tabController;
  final List<Widget> tabChildren;
  final List<ProfileTabData> tabs;

  const ProfileTabsWidget({
    Key? key,
    required this.tabController,
    required this.tabChildren,
    required this.tabs,
  }) : super(key: key);

  // Default constructor for standard profile tabs
  ProfileTabsWidget.standard({
    Key? key,
    required this.tabController,
    required Widget postsTabContent,
    required Widget donateTabContent,
    required Widget wishlistTabContent,
  }) : tabs = const [
          ProfileTabData(
            icon: Icons.grid_on,
            text: 'Posts',
          ),
          ProfileTabData(
            icon: Icons.favorite,
            text: 'Donate',
          ),
          ProfileTabData(
            icon: Icons.shopping_bag,
            text: 'Wishlist',
          ),
        ],
        tabChildren = [postsTabContent, donateTabContent, wishlistTabContent],
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        return Column(
          children: [
            // Grid Tab Bar
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
              child: _buildGridTabBar(),
            ),
            
            // Tab Content
            SizedBox(
              height: Get.height * 0.5, // Reduced from 0.6 to prevent overflow
              child: TabBarView(
                controller: tabController,
                children: tabChildren,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGridTabBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isLast = index == tabs.length - 1;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => tabController.animateTo(index),
              child: Container(
                margin: EdgeInsets.only(right: isLast ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: tabController.index == index 
                      ? const Color(0xFF0095F6).withOpacity(0.1)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: tabController.index == index 
                        ? const Color(0xFF0095F6)
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      tab.icon,
                      size: 24,
                      color: tabController.index == index 
                          ? const Color(0xFF0095F6)
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: tabController.index == index 
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: tabController.index == index 
                            ? const Color(0xFF0095F6)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
