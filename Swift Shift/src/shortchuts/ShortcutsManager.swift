import ShortcutRecorder
import CGEventSupervisor

enum ShortcutType: String, CaseIterable {
    case move = "Move"
    case resize = "Resize"
}

enum MouseButton: String, CaseIterable {
    case none = "None"
    case left = "Left"
    case right = "Right"

    static func parse(rawValue: String?) -> MouseButton {
      guard let rawValue = rawValue else { return .none }
      if let value = MouseButton(rawValue: rawValue) {
        return value
      } else {
        return .none
      }
    }
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
                UserDefaults.standard.set(userShortcut.mouseButton.rawValue, forKey: "\(userShortcut.type.rawValue)_mouseButton")
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
            let mouseButton = MouseButton.parse(rawValue: UserDefaults.standard.string(forKey: "\(type.rawValue)_mouseButton"))
            return UserShortcut(type: type, shortcut: shortcut, mouseButton: mouseButton)
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
    private func addActions(mouseAction: MouseAction, for userShortcut: UserShortcut) {
        guard let shortcut = userShortcut.shortcut else { return }

        let keydownAction = ShortcutAction(shortcut: shortcut) { _ in
            self.startTracking(userShortcut, mouseAction)
            return true
        }
        let keyupAction = ShortcutAction(shortcut: shortcut) { _ in
            self.stopTracking(userShortcut, mouseAction)
            return true
        }
        
        AppDelegate.shared.shortcutMonitor?.addAction(keydownAction, forKeyEvent: .down)
        AppDelegate.shared.shortcutMonitor?.addAction(keyupAction, forKeyEvent: .up)
    }
    
    // Workaround to get those f**kers to work on key-up
    private func addGlobalMonitors(mouseAction: MouseAction, for userShortcut: UserShortcut) {
        guard let shortcut = userShortcut.shortcut else { return }

        // Global events
        if let eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyUp, .keyDown, .flagsChanged], handler: { (event) in
            self.handleFlagsChanged(userShortcut, shortcut, event, mouseAction)
        }) {
            self.globalMonitors.append(eventMonitor)
        }
        // Local events (https://github.com/pablopunk/SwiftShift/issues/10#issuecomment-1872524489)
        if let eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyUp, .keyDown, .flagsChanged], handler: {(event) in
            self.handleFlagsChanged(userShortcut, shortcut, event, mouseAction)
            return event
        }) {
            self.globalMonitors.append(eventMonitor)
        }
    }
    
    private func updateGlobalShortcuts() {
        clearActionsAndMonitors()

        for type in ShortcutType.allCases {
            if let userShortcut = load(for: type), let shortcut = userShortcut.shortcut {
                let mouseAction = type == .move ? MouseAction.move : MouseAction.resize
                let isModifierOnlyShortcut = shortcut.charactersIgnoringModifiers == nil
                
                if isModifierOnlyShortcut {
                    addGlobalMonitors(mouseAction: mouseAction, for: userShortcut)
                } else {
                    addActions(mouseAction: mouseAction, for: userShortcut)
                }
            }
        }
    }
    
    private func handleFlagsChanged(_ userShortcut: UserShortcut, _ shortcut: Shortcut, _ event: NSEvent, _ action: MouseAction) {
        let eventFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        // Sometimes the tracking doesn't stop, so we force it to stop in every flag change
        stopTracking(userShortcut, action)

        if eventFlags == shortcut.modifierFlags {
            startTracking(userShortcut, action)
        }
    }

    private func startTracking(_ userShortcut: UserShortcut, _ action: MouseAction) {
        if userShortcut.mouseButton == .none {
            MouseTracker.shared.startTracking(for: action, button: .none)
            return
        }

        let downEvent: CGEventType = userShortcut.mouseButton == .left ? .leftMouseDown : .rightMouseDown
        let upEvent: CGEventType = userShortcut.mouseButton == .left ? .leftMouseUp : .rightMouseUp

        CGEventSupervisor.shared.subscribe(
            as: "\(action.rawValue)_mouseDown",
            to: .cgEvents(downEvent),
            using: {(event) in
                event.cancel()
                MouseTracker.shared.startTracking(for: action, button: userShortcut.mouseButton)
            });

        CGEventSupervisor.shared.subscribe(
            as: "\(action.rawValue)_mouseUp",
            to: .cgEvents(upEvent),
            using: {(event) in
                event.cancel()
                MouseTracker.shared.stopTracking(for: action)
            });
    }

    private func stopTracking(_ userShortcut: UserShortcut, _ action: MouseAction) {
        MouseTracker.shared.stopTracking(for: action)
        CGEventSupervisor.shared.cancel(subscriber: "\(action.rawValue)_mouseDown")
        CGEventSupervisor.shared.cancel(subscriber: "\(action.rawValue)_mouseUp")
    }
}
