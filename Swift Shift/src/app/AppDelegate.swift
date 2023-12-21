import ShortcutRecorder

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!
    var shortcutMonitor: GlobalShortcutMonitor?

    override init() {
        super.init()
        AppDelegate.shared = self
        self.shortcutMonitor = GlobalShortcutMonitor.shared
    }
}
