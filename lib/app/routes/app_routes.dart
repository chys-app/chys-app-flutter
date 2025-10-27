abstract class AppRoutes {
  static const initial = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const businessHome = '/business-home';
  static const marketplace = '/marketplace';
  static const map = '/map';
  static const addBankInfo = '/addBankInfo';
  static const withdraw = '/withdraw';
  static const fundRaise = '/fundRaise';

  static const settings = '/settings';
  static const notifications = '/notifications';
  static const addPet = '/add-pet';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const pets = '/pets';

  static const petProfile = '/pet-profile';
  static const chat = '/chat';
  static const chatDetail = '/chat-detail';
  static const newChat = '/new-chat';
  static const privacy = '/privacy';
  static const security = '/security';
  static const language = '/language';
  static const helpCenter = '/help-center';
  static const contactUs = '/contact-us';
  static const terms = '/terms';
  static const privacyPolicy = '/privacy-policy';
  static const about = '/about';

  // New routes
  static const addPost = '/add-post';
  static const invitePodcast = '/invite-podcast';
  static const startPodCost = '/start-podcast';
  static const podCastView = '/podcast-view';
  static const inviteUserToPodCast = '/inviteUserToPodCast';
  static const allPodcast = '/allPodcast';
  static const homeDetail = '/home-detail';
  static const subscription = '/subscription';
  static const donate = '/donateView';
  static const donateDetail = '/donateDetail';
  static const donateNow = '/donateNow';
  static const adoredPost = '/adoredPost';
  static const postPreview = '/post-preview';
  static const newPostPreview = '/new-post-preview';

  // Pet onboarding routes
  static const petOwnership = '/pet-ownership';
  static const petSelection = '/pet-selection';
  static const appearance = '/appearance';
  static const identification = '/identification';
  static const behavioral = '/behavioral';
  static const ownerInfo = '/owner-info';
  static const dogBreeds = '/dog-breeds';
  static const cityView = '/city-view';

  // Chat related routes
  static const chatList = '/chat-list';
  static const chatSearch = '/chat-search';
  static const chatSettings = '/chat-settings';

  // Profile related routes
  static const profileEdit = '/profile-edit';
  static const profileSettings = '/profile-settings';
  static const otherUserProfile = '/other-user-profile';
  static const followers = '/followers';
  static const following = '/following';

  // Pet related routes
  static const petEdit = '/pet-edit';
  static const petDetails = '/pet-details';
  static const petHealth = '/pet-health';
  static const petVaccinations = '/pet-vaccinations';
  static const petMedicalHistory = '/pet-medical-history';
  static const petGallery = '/pet-gallery';

  // Pet edit flow routes
  static const petEditProfileFlow = '/pet-edit/profile';
  static const petEditSelectionFlow = '/pet-edit/selection';
  static const petEditAppearanceFlow = '/pet-edit/appearance';
  static const petEditIdentificationFlow = '/pet-edit/identification';
  static const petEditOwnerInfoFlow = '/pet-edit/owner-info';
  static const petEditBehavioralFlow = '/pet-edit/behavioral';

  // Settings related routes
  static const settingsNotifications = '/settings-notifications';
  static const settingsPrivacy = '/settings-privacy';
  static const settingsSecurity = '/settings-security';
  static const settingsLanguage = '/settings-language';
  static const settingsHelp = '/settings-help';
  static const settingsAbout = '/settings-about';
  static const verifyOtpView = '/verifyOtpView';
  static const verifyEmailView = '/verifyEmailView';

  // User management routes
  static const blockedUsers = '/blocked-users';
  static const reportedUsers = '/reported-users';

  // Define the signup flow sequence for easy navigation
  static const List<String> signupFlow = [
    signup,
    petOwnership,
    petSelection,
    petProfile,
    appearance,
    identification,
    ownerInfo,
    dogBreeds,
    cityView,
    map,
    behavioral,
    home,
  ];

  // Helper method to get next route in signup flow
  static String? getNextSignupRoute(String currentRoute) {
    final currentIndex = signupFlow.indexOf(currentRoute);
    if (currentIndex < 0 || currentIndex >= signupFlow.length - 1) {
      return null;
    }
    return signupFlow[currentIndex + 1];
  }

  // Helper method to get previous route in signup flow
  static String? getPreviousSignupRoute(String currentRoute) {
    final currentIndex = signupFlow.indexOf(currentRoute);
    if (currentIndex <= 0) {
      return null;
    }
    return signupFlow[currentIndex - 1];
  }

  static const accountStatus = '/account-status';
  static const transactionHistory = '/transaction-history';

  static const forgetPassword = '/forget-password';
  static const otp = '/otp';
  static const resetPassword = '/reset-password';
  
  // Product routes
  static const productDetail = '/product-detail';
  static const cart = '/cart';
  static const promoteProduct = '/promote-product';
}
