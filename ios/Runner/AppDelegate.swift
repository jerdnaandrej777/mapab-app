import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let navigationBackgroundManager = NavigationBackgroundManager()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    navigationBackgroundManager.register(with: self.binaryMessenger)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
