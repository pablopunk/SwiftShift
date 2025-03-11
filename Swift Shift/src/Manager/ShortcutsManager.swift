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
  private var activeShortcuts: [ShortcutType: Bool] = [:]
  private var mouseSubscriptions: Set<String> = []
  
  private init() {
    // Initialize tracking state for each shortcut type
    for type in ShortcutType.allCases {
      activeShortcuts[type] = false
    }
    updateGlobalShortcuts()
  }
  
  // Public method to cleanup all shortcuts when the app quits
  func cleanupAllShortcuts() {
    // Stop any active tracking
    for type in ShortcutType.allCases {
      if activeShortcuts[type] == true {
        let action = type == .move ? MouseAction.move : MouseAction.resize
        MouseTracker.shared.stopTracking(for: action)
        cleanupMouseSubscriptions(action: action)
      }
    }
    
    // Clear all monitors and actions
    removeGlobalMonitors()
    removeAllActions()
    
    // Reset the active shortcuts state
    for type in ShortcutType.allCases {
      activeShortcuts[type] = false
    }
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
  
  func removeClickActionsForAll() {
    for type in ShortcutType.allCases {
      if var userShortcut = load(for: type) {
        userShortcut.mouseButton = .none
        self.save(userShortcut)
      }
    }
  }
  
  private func clearActionsAndMonitors() {
    removeAllActions()
    removeGlobalMonitors()
    cleanupAllMouseSubscriptions()
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
  
  private func cleanupAllMouseSubscriptions() {
    for subscriptionKey in mouseSubscriptions {
      CGEventSupervisor.shared.cancel(subscriber: subscriptionKey)
    }
    mouseSubscriptions.removeAll()
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
  
  // Handle modifier-only shortcuts with better flag handling
  private func addGlobalMonitors(mouseAction: MouseAction, for userShortcut: UserShortcut) {
    guard let shortcut = userShortcut.shortcut else { return }
    
    let flagsChangedHandler: (NSEvent) -> Void = { [weak self] event in
      guard let self = self else { return }
      
      // Use deviceIndependentFlagsMask for consistent behavior across keyboard layouts
      let eventFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
      let shortcutFlags = shortcut.modifierFlags
      
      let shortcutType = userShortcut.type
      let isActive = self.activeShortcuts[shortcutType] ?? false
      
      if eventFlags == shortcutFlags && !isActive {
        // Shortcut activated - start tracking
        self.startTracking(userShortcut, mouseAction)
        self.activeShortcuts[shortcutType] = true
      } else if eventFlags != shortcutFlags && isActive {
        // Shortcut deactivated - stop tracking
        self.stopTracking(userShortcut, mouseAction)
        self.activeShortcuts[shortcutType] = false
      }
    }
    
    // Global monitor for flagsChanged events only
    if let monitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged], handler: flagsChangedHandler) {
      globalMonitors.append(monitor)
    }
    
    // Also track local events for when the app is in focus
    if let monitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged], handler: { event in
      flagsChangedHandler(event)
      // Always propagate the original event to prevent hijacking
      return event
    }) {
      globalMonitors.append(monitor)
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
  
  private func startTracking(_ userShortcut: UserShortcut, _ action: MouseAction) {
    if userShortcut.mouseButton == .none {
      MouseTracker.shared.startTracking(for: action, button: .none)
      return
    }
    
    let downEvent: CGEventType = userShortcut.mouseButton == .left ? .leftMouseDown : .rightMouseDown
    let upEvent: CGEventType = userShortcut.mouseButton == .left ? .leftMouseUp : .rightMouseUp
    let downKey = "\(action.rawValue)_mouseDown"
    let upKey = "\(action.rawValue)_mouseUp"
    
    // Subscribe to mouse events only if shortcut is active
    CGEventSupervisor.shared.subscribe(
      as: downKey,
      to: .cgEvents(downEvent),
      using: { [weak self] event in
        guard let self = self, self.activeShortcuts[userShortcut.type] == true else { return }
        event.cancel()
        MouseTracker.shared.startTracking(for: action, button: userShortcut.mouseButton)
      })
    
    CGEventSupervisor.shared.subscribe(
      as: upKey,
      to: .cgEvents(upEvent),
      using: { [weak self] event in
        guard let self = self, self.activeShortcuts[userShortcut.type] == true else { return }
        event.cancel()
        MouseTracker.shared.stopTracking(for: action)
      })
    
    // Keep track of our subscriptions
    mouseSubscriptions.insert(downKey)
    mouseSubscriptions.insert(upKey)
  }
  
  private func stopTracking(_ userShortcut: UserShortcut, _ action: MouseAction) {
    MouseTracker.shared.stopTracking(for: action)
    activeShortcuts[userShortcut.type] = false
  }
  
  private func cleanupMouseSubscriptions(action: MouseAction) {
    let downKey = "\(action.rawValue)_mouseDown"
    let upKey = "\(action.rawValue)_mouseUp"
    
    CGEventSupervisor.shared.cancel(subscriber: downKey)
    CGEventSupervisor.shared.cancel(subscriber: upKey)
    
    mouseSubscriptions.remove(downKey)
    mouseSubscriptions.remove(upKey)
  }
}
