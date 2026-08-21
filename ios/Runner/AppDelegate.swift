import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // NOTE: We intentionally do NOT override
  // application(_:supportedInterfaceOrientationsFor:) here.
  //
  // FlutterAppDelegate already implements it to return exactly the
  // orientations requested via SystemChrome.setPreferredOrientations, giving
  // us correct per-screen locking (landscape for the display, portrait for
  // settings/subscription). Overriding it to return `.all` broke that: it told
  // iOS every orientation is always allowed, so on iPad the scene stayed in the
  // device orientation and the landscape-locked content was letterboxed instead
  // of filling the screen.
}
