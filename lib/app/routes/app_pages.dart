import 'package:chys/app/modules/%20home/fundraising_screen.dart';
import 'package:chys/app/modules/%20home/pet_detail.dart';
import 'package:chys/app/modules/%20home/home_view.dart';
import 'package:chys/app/modules/business_home/business_home_binding.dart';
import 'package:chys/app/modules/business_home/business_home_view.dart';
import 'package:chys/app/modules/cart/views/cart_view.dart';
import 'package:chys/app/modules/marketplace/marketplace_view.dart';
import 'package:chys/app/modules/product/views/promote_product_view.dart';
import 'package:chys/app/modules/adored_posts/view/adored_post.dart';
import 'package:chys/app/modules/donate/view/donate_detail.dart';
import 'package:chys/app/modules/donate/view/donate_now.dart';
import 'package:chys/app/modules/donate/view/donate_view.dart';
import 'package:chys/app/modules/podcast/views/all_podcast.dart';
import 'package:chys/app/modules/podcast/views/invite_podcast_view.dart';
import 'package:chys/app/modules/podcast/views/podcost_view.dart';
import 'package:chys/app/modules/podcast/views/start_podcast.dart';
import 'package:chys/app/modules/profile/views/add_bank_info.dart';
import 'package:chys/app/modules/profile/views/edit_profile.dart';
import 'package:chys/app/modules/profile/views/withdraw_view.dart';
import 'package:chys/app/modules/signup/views/email_verify_view.dart';
import 'package:chys/app/modules/signup/views/otp_view.dart';
import 'package:chys/app/modules/splash/view/splash_view.dart';
import 'package:chys/app/modules/subscription/subscription_view.dart';
import 'package:chys/app/modules/transaction/view/transaction_history.dart';
import 'package:get/get.dart';
import '../modules/chat/bindings/chat_binding.dart';
import '../modules/chat/views/chat_detail_view.dart';
import '../modules/chat/views/chat_list_view.dart';
import '../modules/city_view/views/city_view.dart';
import '../modules/dog_breeds/views/dog_breeds_view.dart';
import '../modules/donate/bindings/donate_binding.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/forget_password_view.dart';
import '../modules/login/views/login_view.dart';
import '../modules/login/views/otp_view.dart';
import '../modules/login/views/reset_password_view.dart';
import '../modules/map/bindings/map_binding.dart';
import '../modules/map/views/map_view.dart';
import '../modules/notifications/bindings/notifications_binding.dart';
import '../modules/notifications/views/notifications_view.dart';
import '../modules/owner_info/views/owner_info_view.dart';
import '../modules/pet_appearance/views/appearance_view.dart';
import '../modules/pet_behavioral/views/behavioral_view.dart';
import '../modules/pet_identification/views/identification_view.dart';
import '../modules/pet_ownership/views/pet_ownership_view.dart';
import '../modules/pet_profile/views/pet_profile_view.dart';
import '../modules/pet_selection/views/pet_selection_view.dart';
import '../modules/podcast/bindings/podcast_binding.dart';
import '../modules/post/bindings/post_binding.dart';
import '../modules/post/views/add_post_view.dart';
import '../modules/post/views/post_preview_view.dart';
import '../modules/post/views/new_post_preview_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/profile/views/other_user_profile_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/about_us_view.dart';
import '../modules/settings/views/account_status_view.dart';
import '../modules/settings/views/help_center_view.dart';
import '../modules/settings/views/privacy_view.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/signup/bindings/signup_binding.dart';
import '../modules/signup/views/signup_view.dart';
import '../modules/pet_edit/bindings/pet_edit_binding.dart';
import '../modules/pet_edit/views/edit_profile_view.dart';
import '../modules/pet_edit/views/edit_appearance_view.dart';
import '../modules/pet_edit/views/edit_identification_view.dart';
import '../modules/pet_edit/views/edit_behavioral_view.dart';
import '../modules/pet_edit/views/edit_owner_info_view.dart';
import '../modules/pet_edit/views/edit_selection_view.dart';
import '../modules/user_management/bindings/user_management_binding.dart';
import '../modules/user_management/views/blocked_users_view.dart';
import '../modules/user_management/views/reported_users_view.dart';
import '../modules/product/views/product_detail_view.dart';
import '../data/models/product.dart';
import '../modules/search/search_view.dart';
import '../modules/search/search_binding.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.login;
  static final routes = [
    GetPage(
      name: AppRoutes.initial,
      page: () => const SplashView(),
      preventDuplicates: true,
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginView(),
      binding: LoginBinding(),
      preventDuplicates: true,
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => SignupView(),
      binding: SignupBinding(),
      preventDuplicates: true,
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.petOwnership,
      page: () => const PetOwnershipView(),
      binding: SignupBinding(),
      preventDuplicates: true,
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.petSelection,
      page: () => const PetSelectionView(),
      binding: SignupBinding(),
    ),
    GetPage(
      name: AppRoutes.petProfile,
      page: () => const PetProfileView(),
      binding: SignupBinding(),
      preventDuplicates: true,
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.appearance,
      page: () => const AppearanceView(),
      binding: SignupBinding(),
      preventDuplicates: true,
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.identification,
      page: () => const IdentificationView(),
      binding: SignupBinding(),
      preventDuplicates: true,
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.ownerInfo,
      page: () => const OwnerInfoView(),
      binding: SignupBinding(),
      preventDuplicates: true,
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.dogBreeds,
      page: () => const DogBreedsView(),
      binding: SignupBinding(),
      preventDuplicates: true,
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.cityView,
      page: () => const CityView(),
      binding: SignupBinding(),
      preventDuplicates: true,
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.map,
      page: () => const MapView(),
      binding: MapBinding(),
      preventDuplicates: true,
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.addBankInfo,
      page: () => const AddBankInfoScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.withdraw,
      page: () => WithdrawView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.fundRaise,
      page: () => FundraisingScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.behavioral,
      page: () => const BehavioralView(),
      binding: SignupBinding(),
      preventDuplicates: true,
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => ProfileView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.otherUserProfile,
      page: () => OtherUserProfileView(),
      binding: ProfileBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatListView(),
      binding: ChatBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.chatDetail,
      page: () => ChatDetailView(),
      binding: ChatBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.addPost,
      page: () => AddPostView(),
      binding: PostBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.postPreview,
      page: () => const PostPreviewView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.newPostPreview,
      page: () => const NewPostPreviewView(),
      binding: PostBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.invitePodcast,
      page: () => InvitePodcastView(),
      binding: PodcastBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.startPodCost,
      page: () => StartPodcastScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.podCastView,
      page: () => const PodcastView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.inviteUserToPodCast,
      page: () => InvitePodcastView(),
      binding: PodcastBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.allPodcast,
      page: () => const AllPodcast(),
      binding: PodcastBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.settingsNotifications,
      page: () => SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.settingsPrivacy,
      page: () => SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.settingsSecurity,
      page: () => SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.settingsLanguage,
      page: () => SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.settingsHelp,
      page: () => SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.settingsAbout,
      page: () => SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.verifyOtpView,
      page: () => const VerifyOtpScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.verifyEmailView,
      page: () => EmailVerificationScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.blockedUsers,
      page: () => const BlockedUsersView(),
      binding: UserManagementBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.reportedUsers,
      page: () => const ReportedUsersView(),
      binding: UserManagementBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => EditProfile(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => HomeView(),
      binding: PostBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.businessHome,
      page: () => const BusinessHomeView(),
      binding: BusinessHomeBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.marketplace,
      page: () => const MarketplaceView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchView(),
      binding: SearchBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.homeDetail,
      page: () => PetDetail(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.subscription,
      page: () => const SubscriptionView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.donate,
      page: () => DonateView(),
      binding: DonateBinding(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.donateDetail,
      page: () => const DonateDetail(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.donateNow,
      page: () => DonateNow(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.adoredPost,
      page: () => AdoredPost(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.accountStatus,
      page: () => const AccountStatusView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.privacy,
      page: () => const PrivacyView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.about,
      page: () => const AboutUsView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.helpCenter,
      page: () => const HelpCenterView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.transactionHistory,
      page: () => const TransactionHistoryView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.forgetPassword,
      page: () => ForgetPasswordView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.otp,
      page: () => OtpView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.resetPassword,
      page: () => ResetPasswordView(),
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: AppRoutes.petEditProfileFlow,
      page: () => const EditPetProfileView(),
      binding: PetEditBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.petEditAppearanceFlow,
      page: () => const EditAppearanceView(),
      binding: PetEditBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.petEditIdentificationFlow,
      page: () => const EditIdentificationView(),
      binding: PetEditBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.petEditBehavioralFlow,
      page: () => const EditBehavioralView(),
      binding: PetEditBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.petEditOwnerInfoFlow,
      page: () => const EditOwnerInfoView(),
      binding: PetEditBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.petEditSelectionFlow,
      page: () => const EditPetSelectionView(),
      binding: PetEditBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.petDetails,
      page: () => PetDetail(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.productDetail,
      page: () {
        final product = Get.arguments as Products;
        return ProductDetailView(product: product);
      },
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.cart,
      page: () => CartView(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: AppRoutes.promoteProduct,
      page: () {
        final product = Get.arguments as Products;
        return PromoteProductView(product: product);
      },
      transition: Transition.cupertino,
    ),
  ];

  static String getRoute(String name) {
    print('DEBUG: Getting route for: $name');
    final route = routes.firstWhere(
      (route) => route.name == name,
      orElse: () => throw Exception('Route $name not found'),
    );
    print('DEBUG: Found route: ${route.name}');
    return route.name;
  }
}
