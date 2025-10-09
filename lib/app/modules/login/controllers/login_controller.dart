import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:chys/app/modules/signup/controller/signup_controller.dart';
import 'package:chys/app/services/short_message_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/controllers/loading_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../map/controllers/map_controller.dart';

class LoginController extends GetxController {
  final _apiService = ApiService();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String userEmail = "";
  String userPassword = "";
  String emailText = "";
  String passwordText = "";
  final showPassword = false.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Always ensure controllers are fresh
    try { 
      emailController = TextEditingController();
    } catch (e) {
      emailController = TextEditingController();
    }
    try {
      passwordController = TextEditingController();
    } catch (e) {
      passwordController = TextEditingController();
    }
  } //fojakot776@endibit.com

//liyapi2789@jxbav.com
  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  Future<void> handleLogin({bool isSocial = false}) async {
    final loading = Get.find<LoadingController>();
    try {
      if (!isSocial && !_validateForm()) return;
      if (!isSocial) {
        userEmail = emailText;
        userPassword = passwordText;
      }

      isLoading.value = true;
      loading.show();

      final result = await _apiService.login(
        email: userEmail,
        password: userPassword,
      );

      loading.hide();

      if (result['success']) {
        log("Response for login is $result");

        // Don't clear storage here as the API service already saves user data
        // await StorageService.clearStorage();
        await StorageService.saveToken(result['data']['token']);

        // Verify user data was saved
        final userData = StorageService.getUser();
        log("User data after login: $userData");

        // Clear all input values after successful login
        clearFields();

        Future.microtask(() => Get.put(MapController()).selectFeature("user"));
      } else {
        if (result["message"] ==
            "Your email is not verified. A new verification link has been sent to your email.") {
          Get.put(SignupController());
          Get.offAllNamed(AppRoutes.verifyEmailView);
        }
        ShortMessageUtils.showError(result["message"]);
      }
    } catch (e) {
      loading.hide();
      ShortMessageUtils.showError("Error during login: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void clearFields() {
    emailController.clear();
    passwordController.clear();
    userEmail = "";
    userPassword = "";
    showPassword.value = false;
  }

  bool _validateForm() {
    if (emailText.isEmpty) {
      Get.snackbar('Error', 'Please enter your email',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (passwordText.isEmpty) {
      Get.snackbar('Error', 'Please enter your password',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    return true;
  }

  void navigateToSignup() {
    Get.toNamed(AppRoutes.signup);
  }

  Future<void> loginWithGoogle() async {
    final loading = Get.find<LoadingController>();
    try {
      loading.show();
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        userEmail = googleUser.email;
        userPassword = googleUser.email;
        loading.hide();
        await handleLogin(isSocial: true);
        log("✅ Google login successful!");
        log("Access Token: ${googleAuth.accessToken}");
        log("ID Token: ${googleAuth.idToken}");
        log("User ID: ${googleUser.id}");
        log("Name: ${googleUser.displayName}");
        log("Email: ${googleUser.email}");
        log("Photo URL: ${googleUser.photoUrl}");
        // Optional: send googleAuth.idToken to your backend for verification
      } else {
        loading.hide();
        log("❌ Google sign-in canceled by user.");
      }
    } catch (e) {
      loading.hide();
      log("🔥 Google login error: $e");
    }
  }

  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = math.Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the SHA256 hash of the nonce
  String sha256ofNonce(String nonce) {
    final bytes = utf8.encode(nonce);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> signInWithApple() async {
    final loading = Get.find<LoadingController>();

    try {
      loading.show();
      final rawNonce = generateNonce();
      final hashedNonce = sha256ofNonce(rawNonce);
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      userEmail = credential.email!;
      userPassword = credential.email!;
      loading.hide();
      await handleLogin(isSocial: true);
      log("✅ Apple Sign-In Successful!");
      log("User ID: ${credential.userIdentifier}");
      log("Email: ${credential.email}");
      log("Full Name: ${credential.givenName} ${credential.familyName}");
      log("Identity Token: ${credential.identityToken}");
      log("Authorization Code: ${credential.authorizationCode}");
      log("Raw Nonce (send to backend): $rawNonce");
      loading.hide();
    } catch (e) {
      loading.hide();
      log("🔥 Apple Sign-In Error: $e");
    }
  }

  @override
  void onClose() {
    // Clear and dispose controllers when leaving the screen
    clearFields();
    try {
      emailController.dispose();
      passwordController.dispose();
    } catch (e) {
      // Controllers might already be disposed, ignore the error
    }
    super.onClose();
  }
}
