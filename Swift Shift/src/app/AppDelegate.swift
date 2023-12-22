import ShortcutRecorder

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!
    var shortcutMonitor: AXGlobalShortcutMonitor?

    override init() {
        super.init()
        AppDelegate.shared = self
        self.shortcutMonitor = AXGlobalShortcutMonitor()
    }
}
