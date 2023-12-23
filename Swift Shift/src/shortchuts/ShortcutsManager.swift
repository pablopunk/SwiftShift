import ShortcutRecorder

enum ShortcutType: String, CaseIterable {
    case move = "Move"
    case resize = "Resize"
}

struct UserShortcut {
    var type: ShortcutType
    var shortcut: Shortcut?
}

class ShortcutsManager {
    static let shared = ShortcutsManager()
    var globalMonitors: [Any] = []
    
    private init() {
        updateGlobalShortcuts()
    }
    
    func save(_ userShortcut: UserShortcut) {
        do {
            if let shortcut = userShortcut.shortcut {
                let data = try NSKeyedArchiver.archivedData(withRootObject: shortcut, requiringSecureCoding: false)
                UserDefaults.standard.set(data, forKey: userShortcut.type.rawValue)
            }
        } catch {
            print("Error: \(error)")
        }
        updateGlobalShortcuts()
    }
    
    func load(for type: ShortcutType) -> UserShortcut? {
        guard let data = UserDefaults.standard.data(forKey: type.rawValue) else { return nil }
        do {
            let shortcut = try NSKeyedUnarchiver.unarchivedObject(ofClass: Shortcut.self, from: data)
            return UserShortcut(type: type, shortcut: shortcut)
        } catch {
            print("Error unarchiving data: \(error.localizedDescription)")
            return nil
        }
    }
    
    func delete(for type: ShortcutType) {
        UserDefaults.standard.removeObject(forKey: type.rawValue)
        updateGlobalShortcuts()
    }
    
    private func removeGlobalMonitors() {
        for monitor in self.globalMonitors {
            NSEvent.removeMonitor(monitor)
        }
        self.globalMonitors = []
    }
    
    private func updateGlobalShortcuts() {
        AppDelegate.shared.shortcutMonitor?.removeAllActions()
        removeGlobalMonitors()
        
        for type in ShortcutType.allCases {
            let userShortcut = load(for: type)
            if let shortcut = userShortcut?.shortcut {
                let mouseAction = type == .move ? MouseAction.move : MouseAction.resize
                
                let keydownAction = ShortcutAction(shortcut: shortcut) { _ in
                    MouseTracker.shared.startTracking(for: mouseAction)
                    return true
                }
                let keyupAction = ShortcutAction(shortcut: shortcut) { _ in
                    MouseTracker.shared.stopTracking()
                    return true
                }
                // Regular shortcuts that should work fine except for modifier-only shortcuts on key-up
                AppDelegate.shared.shortcutMonitor?.addAction(keydownAction, forKeyEvent: .down)
                AppDelegate.shared.shortcutMonitor?.addAction(keyupAction, forKeyEvent: .up)
                // Workaround to get those f**kers to work on key-up
                if let eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: { (event) in
                    ShortcutsManager.handleFlagsChanged(shortcut, event, mouseAction)
                }) {
                    self.globalMonitors.append(eventMonitor)
                }
            }
        }
    }
    
    private static func handleFlagsChanged(_ shortcut: Shortcut, _ event: NSEvent, _ action: MouseAction) {
        if event.modifierFlags.isDisjoint(with: shortcut.modifierFlags) {
            MouseTracker.shared.stopTracking()
        } else if event.modifierFlags.contains(shortcut.modifierFlags) {
            MouseTracker.shared.startTracking(for: action)
        }
    }
}
