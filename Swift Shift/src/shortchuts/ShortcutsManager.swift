import Foundation
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
    
    private init() {
        updateGlobalShortcuts()
    }
    
    func save(_ shortcut: UserShortcut) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: shortcut.shortcut, requiringSecureCoding: false)
            UserDefaults.standard.set(data, forKey: shortcut.type.rawValue)
        } catch {
            print("Error: \(error)")
        }
        updateGlobalShortcuts()
    }
    
    func load(for type: ShortcutType) -> UserShortcut? {
        guard let data = UserDefaults.standard.data(forKey: type.rawValue),
              let shortcut = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? Shortcut else {
            return nil
        }
        return UserShortcut(type: type, shortcut: shortcut)
    }
    
    func delete(for type: ShortcutType) {
        UserDefaults.standard.removeObject(forKey: type.rawValue)
        updateGlobalShortcuts()
    }
    
    private func updateGlobalShortcuts() {
        AppDelegate.shared.shortcutMonitor?.removeAllActions()
        
        for type in ShortcutType.allCases {
            let userShortcut = load(for: type)
            if let shortcut = userShortcut?.shortcut {
                let actionType = type == .move ? MouseAction.move : MouseAction.resize
                
                let keydownAction = ShortcutAction(shortcut: shortcut) { _ in
                    MouseTracker.shared.startTracking(for: actionType)
                    return true
                }
                let keyupAction = ShortcutAction(shortcut: shortcut) { _ in
                    MouseTracker.shared.stopTracking()
                    return true
                }
                AppDelegate.shared.shortcutMonitor?.addAction(keydownAction, forKeyEvent: .down)
                AppDelegate.shared.shortcutMonitor?.addAction(keyupAction, forKeyEvent: .up)
            }
        }
    }
}
