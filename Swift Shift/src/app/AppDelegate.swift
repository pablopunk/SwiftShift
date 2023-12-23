import ShortcutRecorder
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!
    var shortcutMonitor: AXGlobalShortcutMonitor?
    
    override init() {
        super.init()
        AppDelegate.shared = self
        self.shortcutMonitor = AXGlobalShortcutMonitor()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        UserDefaults.standard.set(true, forKey: "showMenuBarIcon")
        return true
    }
}
