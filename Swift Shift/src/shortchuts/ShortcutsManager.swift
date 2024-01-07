import ShortcutRecorder

enum ShortcutType: String, CaseIterable {
    case move = "Move"
    case resize = "Resize"
}

enum MouseButton: String, CaseIterable {
    case none = "None"
    case left = "Left"
    case right = "Right"
}

struct UserShortcut {
    var type: ShortcutType
    var shortcut: Shortcut?
    var mouseButton: MouseButton
    
    init(type: ShortcutType, shortcut: Shortcut? = nil, mouseButton: MouseButton) {
        self.type = type
        self.shortcut = shortcut
        self.mouseButton = mouseButton
    }
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
            // TODO: mouseButton should also be saved in save() and retrieved here
            return UserShortcut(type: type, shortcut: shortcut, mouseButton: .none)
        } catch {
            print("Error unarchiving data: \(error.localizedDescription)")
            return nil
        }
    }
    
    func delete(for type: ShortcutType) {
        UserDefaults.standard.removeObject(forKey: type.rawValue)
        updateGlobalShortcuts()
    }
    
    private func clearActionsAndMonitors() {
        removeAllActions()
        removeGlobalMonitors()
    }
    
    private func removeAllActions() {
        AppDelegate.shared.shortcutMonitor?.removeAllActions()
    }
    
    private func removeGlobalMonitors() {
        for monitor in self.globalMonitors {
            NSEvent.removeMonitor(monitor)
        }
        self.globalMonitors = []
    }
    
    // Regular shortcuts that should work fine except for modifier-only shortcuts on key-up
    private func addActions(mouseAction: MouseAction, for shortcut: Shortcut) {
        let keydownAction = ShortcutAction(shortcut: shortcut) { _ in
            MouseTracker.shared.startTracking(for: mouseAction)
            return true
        }
        let keyupAction = ShortcutAction(shortcut: shortcut) { _ in
            MouseTracker.shared.stopTracking(for: mouseAction)
            return true
        }
        
        AppDelegate.shared.shortcutMonitor?.addAction(keydownAction, forKeyEvent: .down)
        AppDelegate.shared.shortcutMonitor?.addAction(keyupAction, forKeyEvent: .up)
    }
    
    // Workaround to get those f**kers to work on key-up
    private func addGlobalMonitors(mouseAction: MouseAction, for shortcut: Shortcut) {
        // Global events
        if let eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: { (event) in
            self.handleFlagsChanged(shortcut, event, mouseAction)
        }) {
            self.globalMonitors.append(eventMonitor)
        }
        // Local events (https://github.com/pablopunk/SwiftShift/issues/10#issuecomment-1872524489)
        if let eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged, handler: {(event) in
            self.handleFlagsChanged(shortcut, event, mouseAction)
            return event
        }) {
            self.globalMonitors.append(eventMonitor)
        }
        
    }
    
    private func updateGlobalShortcuts() {
        clearActionsAndMonitors()
        
        for type in ShortcutType.allCases {
            let userShortcut = load(for: type)
            if let shortcut = userShortcut?.shortcut {
                let mouseAction = type == .move ? MouseAction.move : MouseAction.resize
                addActions(mouseAction: mouseAction, for: shortcut)
                addGlobalMonitors(mouseAction: mouseAction, for: shortcut)
            }
        }
    }
    
    private func handleFlagsChanged(_ shortcut: Shortcut, _ event: NSEvent, _ action: MouseAction) {
        let eventFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if eventFlags.isDisjoint(with: shortcut.modifierFlags) {
            MouseTracker.shared.stopTracking(for: action)
        } else if eventFlags == shortcut.modifierFlags {
            MouseTracker.shared.startTracking(for: action)
        }
    }
}
