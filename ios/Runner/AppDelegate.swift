import UIKit
import Flutter
import Firebase
import UserNotifications
import GoogleMaps
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase
    FirebaseApp.configure()
    GMSServices.provideAPIKey("AIzaSyDMyYpKuEFu4cwuUhY5ocriK1rDHcYE52k")

    // Set UNUserNotificationCenter delegate (for foreground notification handling)
    UNUserNotificationCenter.current().delegate = self


    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }



  // ✅ Optional: If you disabled FirebaseAppDelegateProxyEnabled
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}
