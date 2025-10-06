class AppImages {
  static const String _basePath = 'assets/images/';
  static String svgImage(String fileName) => '$_basePath$fileName.svg';
  static String lottieAnimation(String fileName) =>
      'assets/json/$fileName.json';

  static const String image1 = '${_basePath}image1.png';
  static const String dog = "${_basePath}dog.png";
  static const String cat = "${_basePath}cat.png";
  static const String upload = "${_basePath}upload.png";
  static const String profile = '${_basePath}profile.png';
  static const String onboard = "${_basePath}onboard.png";
  static const String banner = '${_basePath}banner.jpg';
  static const String iconHome = '${_basePath}icon_home.svg';
  static const String iconSettings = '${_basePath}icon_settings.svg';
  static const String other = "${_basePath}other.png";
  static const String post = "${_basePath}post.png";
  static const String discount = "${_basePath}discount.png";
  static const String logo = '${_basePath}appLogo.png';
  static const String appLogo = '${_basePath}logo.png';
  static const String podCastImage = '${_basePath}podcast.png';

  static String add = svgImage("add");
  static String podcast = svgImage("podcast");
  static String user = svgImage("profile");
  static String map = svgImage("map");
  static String chat = svgImage("chat");
  static String edit = svgImage("edit");
  static String paw = svgImage("paw_outline");
  static String pawFilled = svgImage("paw_filled_outline");
  static String follow = svgImage("follow");
  static String unfollow = svgImage("unfollow");
  static String message = svgImage("message");
  static String share = svgImage("share");
  static String love = svgImage("love");
  static String male = svgImage("male");
  static String podcastMic = svgImage("podcastMic");
  static String send = svgImage("send");
  static String account = svgImage("account");
  static String catPaw = svgImage("catPaw");
  static String subscription = svgImage("subscription");
  static String donate = svgImage("donate");
  static String notification = svgImage("notification");
  static String help = svgImage("help");
  static String privacy = svgImage("privacy");
  static String about = svgImage("about");
  static String logout = svgImage("logout");
  static String podcastIcon = svgImage("podcastIcon");
  static String history = svgImage("history");
  static String cash = svgImage("cash");
  static String bankInfo = svgImage("bankInfo");
  static String gift = svgImage("gift");

  //lottie
  static String empty = lottieAnimation("empty");
  static String emptyChat = lottieAnimation("emptyChat");
  static String emptyPodcast = lottieAnimation("emptyPodcast");
}
