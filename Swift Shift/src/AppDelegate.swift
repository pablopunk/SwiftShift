import ShortcutRecorder
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
  static var shared: AppDelegate!
  var shortcutMonitor: GlobalShortcutMonitor?
  
  // Add a property to track global keydown events
  private var keyboardMonitor: Any?
  
  override init() {
    super.init()
    AppDelegate.shared = self
    self.shortcutMonitor = GlobalShortcutMonitor()
  }
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    let _ = ShortcutsManager.shared // immediately register shortcuts so we won't wait for the UI
    
    // Register for notifications to detect interactions with other apps
    registerForAppStateNotifications()
    
    // Setup global keyboard monitoring
    setupKeyboardMonitor()
  }
  
  private func setupKeyboardMonitor() {
    // Monitor global keyboard events to detect when other apps might need shortcuts
    keyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
      // If any key is pressed, temporarily pause our tracking
      // This allows other apps to process their shortcuts without interference
      if event.type == .keyDown {
        MouseTracker.shared.pauseTracking()
      } else if event.type == .keyUp {
        // On key up, we can resume tracking if appropriate
        // Add a slight delay to ensure the other app has processed the shortcut
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          MouseTracker.shared.resumeTracking()
        }
      }
    }
  }
  
  private func registerForAppStateNotifications() {
    // Watch for app activation/deactivation events
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAppDeactivation),
      name: NSApplication.didResignActiveNotification,
      object: nil
    )
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAppActivation),
      name: NSApplication.didBecomeActiveNotification,
      object: nil
    )
  }
  
  @objc private func handleAppDeactivation(_ notification: Notification) {
    // When app is deactivated, pause tracking to let other apps process shortcuts
    MouseTracker.shared.pauseTracking()
  }
  
  @objc private func handleAppActivation(_ notification: Notification) {
    // When app is activated again, resume tracking if appropriate
    MouseTracker.shared.resumeTracking()
  }
  
  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    UserDefaults.standard.set(true, forKey: "showMenuBarIcon")
    return true
  }
  
  func applicationWillTerminate(_ notification: Notification) {
    // Ensure all shortcuts are properly cleaned up when the app quits
    shortcutMonitor?.removeAllActions()
    ShortcutsManager.shared.cleanupAllShortcuts()
    
    // Remove the keyboard monitor
    if let monitor = keyboardMonitor {
      NSEvent.removeMonitor(monitor)
      keyboardMonitor = nil
    }
    
    // Remove observers
    NotificationCenter.default.removeObserver(self)
  }
}
