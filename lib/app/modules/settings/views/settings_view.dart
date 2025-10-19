import 'dart:async';

import 'package:chys/app/core/const/app_image.dart';
import 'package:chys/app/core/const/app_colors.dart';
import 'package:chys/app/modules/profile/controllers/profile_controller.dart';
import 'package:chys/app/modules/adored_posts/controller/controller.dart';
import 'package:chys/app/modules/user_management/controllers/user_management_controller.dart';
import 'package:chys/app/modules/map/controllers/map_controller.dart';
import 'package:chys/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:developer';

import '../../../core/const/app_text.dart';
import '../../../services/storage_service.dart';
import 'package:chys/app/modules/login/controllers/login_controller.dart';

class SettingsView extends StatelessWidget {
  final controller = Get.find<ProfileController>();
  SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Account Section
          _buildSectionTitle('Account'),
          _buildSection([
            _buildInstagramTile('Account Status', Icons.account_circle_outlined, onTap: () {
              Get.toNamed(AppRoutes.accountStatus);
            }),
            _buildInstagramTile('Bank Information', Icons.account_balance_outlined, onTap: () {
              Get.toNamed(AppRoutes.addBankInfo);
            }),
            _buildInstagramTile('Withdraw', Icons.monetization_on_outlined, onTap: () {
              Get.toNamed(AppRoutes.withdraw);
            }),
            _buildInstagramTile('Transaction History', Icons.history_outlined, onTap: () {
              Get.toNamed(AppRoutes.transactionHistory);
            }),
          ]),
          
          const SizedBox(height: 24),
          
          // Support Section
          _buildSectionTitle('Support'),
          _buildSection([
            _buildInstagramTile('Help Center', Icons.help_outline, onTap: () {
              Get.toNamed(AppRoutes.helpCenter);
            }),
          ]),
          
          const SizedBox(height: 24),
          
          // Privacy & Safety Section
          _buildSectionTitle('Privacy & Safety'),
          _buildSection([
            _buildInstagramTile('Notifications', Icons.notifications_outlined, onTap: () {
              Get.toNamed(AppRoutes.notifications);
            }),
            _buildInstagramTile('Privacy', Icons.privacy_tip_outlined, onTap: () {
              Get.toNamed(AppRoutes.privacy);
            }),
            _buildInstagramTile('Blocked Users', Icons.block_outlined, onTap: () {
              Get.toNamed(AppRoutes.blockedUsers);
            }),
            _buildInstagramTile('Reported Users', Icons.report_outlined, onTap: () {
              Get.toNamed(AppRoutes.reportedUsers);
            }),
          ]),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSectionTitle('About'),
          _buildSection([
            _buildInstagramTile('About Us', Icons.info_outline, onTap: () {
              Get.toNamed(AppRoutes.about);
            }),
          ]),
          
          const SizedBox(height: 32),
          
          // Logout Button
          _buildLogoutButton(),
          
          const SizedBox(height: 16),
          
          // Delete Account Button
          _buildDeleteButton(),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSection(List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: List.generate(
          tiles.length * 2 - 1,
          (index) => index.isEven
              ? tiles[index ~/ 2]
              : Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 0.5,
                  color: AppColors.border,
                ),
        ),
      ),
    );
  }

  Widget _buildInstagramTile(String label, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        final confirmed = await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text(
              'Log Out',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            content: const Text(
              'Are you sure you want to log out?',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () => Get.back(result: false),
              ),
              TextButton(
                child: Text(
                  'Log Out',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => Get.back(result: true),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await _performLogout();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.logout_outlined,
                size: 24,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 16),
              const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: () async {
        final confirmed = await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text(
              'Delete Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            content: const Text(
              'This will permanently remove your profile, data, and all content. This action cannot be undone.\n\nAre you sure?',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () => Get.back(result: false),
              ),
              TextButton(
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () async {
                  try {
                    // Show password confirmation dialog
                    final password = await _showPasswordDialog();
                    if (password != null && password.isNotEmpty) {
                      // Delete account first
                      await controller.deleteUserAccount(password);
                      
                      // Wait a moment for the success message to show
                      await Future.delayed(const Duration(milliseconds: 500));
                      
                      // Then perform logout
                      await _performLogout();
                    }
                  } catch (e) {
                    log("❌ Error during account deletion: $e");
                    // Even if account deletion fails, still logout to clear invalid state
                    await _performLogout();
                  }
                },
              ),
            ],
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 24,
                color: AppColors.error,
              ),
              const SizedBox(width: 16),
              const Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Comprehensive logout function that clears all cache data
  Future<void> _performLogout() async {
    try {
      log("🔄 Starting comprehensive logout process...");
      
      // 1. Clear all storage data first
      log("🗑️ Clearing all storage data...");
      await StorageService.clearStorage();
      await StorageService.clearPetProfileDraft();
      
      // 2. Clear controller caches
      log("🗑️ Clearing controller caches...");
      _clearControllerCaches();
      
      // 3. Clear all controllers immediately
      log("🗑️ Clearing all controllers...");
      Get.deleteAll();
      
      // 4. Reinitialize LoginController
      log("🔄 Reinitializing LoginController...");
      Get.put(LoginController());
      
      // 5. Navigate to login
      log("🔄 Navigating to login...");
      Get.offAllNamed(AppRoutes.login);
      
      log("✅ Logout process completed successfully");
      
    } catch (e) {
      log("❌ Error during logout: $e");
      // Even if there's an error, ensure LoginController is available and navigate to login
      try {
        Get.deleteAll();
        Get.put(LoginController());
        Get.offAllNamed(AppRoutes.login);
      } catch (controllerError) {
        log("⚠️ Error initializing LoginController: $controllerError");
        // Force navigation to login even if controller initialization fails
        Get.offAllNamed(AppRoutes.login);
      }
    }
  }

  /// Clear caches from various controllers
  void _clearControllerCaches() {
    try {
      // Clear posts controller cache
      if (Get.isRegistered<AddoredPostsController>()) {
        final postsController = Get.find<AddoredPostsController>();
        postsController.clearAllCache();
        log("🗑️ Cleared posts controller cache");
      }
      
      // Clear profile controller data
      if (Get.isRegistered<ProfileController>()) {
        final profileController = Get.find<ProfileController>();
        profileController.clearProfileData();
        log("🗑️ Cleared profile controller data");
      }
      
      // Clear any other controller caches here
      // Add more controllers as needed
      
    } catch (e) {
      log("⚠️ Error clearing controller caches: $e");
    }
  }

  /// Shows a password confirmation dialog for deleting the account.
  Future<String?> _showPasswordDialog() async {
    final Completer<String?> completer = Completer<String?>();
    
    await Get.dialog<String>(
      _PasswordDialog(
        onResult: (String? password) {
          completer.complete(password);
        },
      ),
    );
    
    return completer.future;
  }
}

/// Custom dialog widget for password confirmation
class _PasswordDialog extends StatefulWidget {
  final Function(String? password) onResult;
  
  const _PasswordDialog({required this.onResult});
  
  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: const Text(
        'Confirm Deletion',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your password to confirm account deletion.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.blue),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          onPressed: () {
            widget.onResult(null);
            Get.back();
          },
        ),
        TextButton(
          child: const Text(
            'Delete',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              widget.onResult(_passwordController.text);
              Get.back();
            }
          },
        ),
      ],
    );
  }
}

