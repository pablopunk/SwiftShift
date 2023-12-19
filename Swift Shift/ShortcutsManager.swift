import Foundation
import ShortcutRecorder

class ShortcutsManager {
    static let shared = ShortcutsManager()
    private let userDefaultsKey = "userShortcut"

    var shortcut: Shortcut? {
        didSet {
            if let shortcut = shortcut {
                saveShortcut(shortcut)
            } else {
                UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            }
            updateGlobalShortcut(shortcut)
        }
    }

    private init() {
        loadSavedShortcut()
    }

    private func saveShortcut(_ shortcut: Shortcut) {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: shortcut, requiringSecureCoding: false) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    private func loadSavedShortcut() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let shortcut = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? Shortcut else {
            self.shortcut = nil
            return
        }
        self.shortcut = shortcut
    }

    private func updateGlobalShortcut(_ newShortcut: Shortcut?) {
        AppDelegate.shared.shortcutMonitor?.removeAllActions()

        if let newShortcut = newShortcut {
            let action = ShortcutAction(shortcut: newShortcut) { _ in
                print("Shortcut activated")
                return true
            }
            AppDelegate.shared.shortcutMonitor?.addAction(action, forKeyEvent: .down)
        }
    }

    func clearShortcut() {
        self.shortcut = nil
    }
}
