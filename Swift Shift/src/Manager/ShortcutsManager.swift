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
  private(set) var activeShortcuts: [ShortcutType: Bool] = [:]
  private var mouseSubscriptions: Set<String> = []
  private var workspaceNotificationObserver: Any?
  
  private init() {
    for type in ShortcutType.allCases {
      activeShortcuts[type] = false
    }
    registerForWorkspaceNotifications()
    updateGlobalShortcuts()
  }
  
  deinit {
    unregisterForWorkspaceNotifications()
  }
  
  private func registerForWorkspaceNotifications() {
    let notificationCenter = NSWorkspace.shared.notificationCenter
    workspaceNotificationObserver = notificationCenter.addObserver(
      forName: NSWorkspace.activeSpaceDidChangeNotification,
      object: nil,
      queue: .main) { [weak self] _ in
        self?.handleSpaceChange()
      }
  }
  
  private func unregisterForWorkspaceNotifications() {
    if let observer = workspaceNotificationObserver {
      NSWorkspace.shared.notificationCenter.removeObserver(observer)
      workspaceNotificationObserver = nil
    }
  }
  
  private func handleSpaceChange() {
    for type in ShortcutType.allCases {
      if activeShortcuts[type] == true {
        activeShortcuts[type] = false
      }
    }
  }
  
  func cleanupAllShortcuts() {
    for type in ShortcutType.allCases {
      if activeShortcuts[type] == true {
        let action = type == .move ? MouseAction.move : MouseAction.resize
        MouseTracker.shared.stopTracking(for: action)
        cleanupMouseSubscriptions(action: action)
      }
    }
    removeGlobalMonitors()
    removeAllActions()
    for type in ShortcutType.allCases {
      activeShortcuts[type] = false
    }
    unregisterForWorkspaceNotifications()
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
  
  // Regular shortcuts (key + modifiers)
  private func addActions(mouseAction: MouseAction, for userShortcut: UserShortcut) {
    guard let shortcut = userShortcut.shortcut else { return }
    
    let keydownAction = ShortcutAction(shortcut: shortcut) { _ in
      self.activeShortcuts[userShortcut.type] = true
      self.startTracking(userShortcut, mouseAction)
      return true
    }
    
    let keyupAction = ShortcutAction(shortcut: shortcut) { _ in
      self.stopTracking(userShortcut, mouseAction)
      self.activeShortcuts[userShortcut.type] = false
      return true
    }
    
    AppDelegate.shared.shortcutMonitor?.addAction(keydownAction, forKeyEvent: .down)
    AppDelegate.shared.shortcutMonitor?.addAction(keyupAction, forKeyEvent: .up)
  }
  
  // Handle modifier-only shortcuts
  private func addGlobalMonitors(mouseAction: MouseAction, for userShortcut: UserShortcut) {
    guard let shortcut = userShortcut.shortcut else { return }
    
    let flagsChangedHandler: (NSEvent) -> Void = { [weak self] event in
      guard let self = self else { return }
      
      let eventFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
      let shortcutFlags = shortcut.modifierFlags
      let shortcutType = userShortcut.type
      let isActive = self.activeShortcuts[shortcutType] ?? false
      let keysDown = self.checkForAdditionalKeysDown()
      
      if eventFlags == shortcutFlags && !isActive && !keysDown {
        self.startTracking(userShortcut, mouseAction)
        self.activeShortcuts[shortcutType] = true
      } else if eventFlags != shortcutFlags && isActive {
        self.stopTracking(userShortcut, mouseAction)
        self.activeShortcuts[shortcutType] = false
      }
    }
    
    if let monitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged], handler: flagsChangedHandler) {
      globalMonitors.append(monitor)
    }
    
    // Monitor key events to release shortcut when non-modifier keys are pressed
    if let monitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp], handler: { [weak self] event in
      guard let self = self else { return }
      
      for type in ShortcutType.allCases {
        if self.activeShortcuts[type] == true {
          let action = type == .move ? MouseAction.move : MouseAction.resize
          if let loaded = self.load(for: type) {
            self.stopTracking(loaded, action)
          } else {
            MouseTracker.shared.stopTracking(for: action)
          }
          self.activeShortcuts[type] = false
        }
      }
    }) {
      globalMonitors.append(monitor)
    }
    
    if let monitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged], handler: { event in
      flagsChangedHandler(event)
      return event
    }) {
      globalMonitors.append(monitor)
    }
  }
  
  private func checkForAdditionalKeysDown() -> Bool {
    guard let currentEvent = NSApp.currentEvent else { return false }
    switch currentEvent.type {
    case .keyDown, .keyUp:
      let nonModifierKeyCodes = Set<UInt16>(36...126)
      if nonModifierKeyCodes.contains(currentEvent.keyCode) {
        return true
      }
    default:
      break
    }
    return false
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
    
    mouseSubscriptions.insert(downKey)
    mouseSubscriptions.insert(upKey)
  }
  
  private func stopTracking(_ userShortcut: UserShortcut, _ action: MouseAction) {
    MouseTracker.shared.stopTracking(for: action)
    cleanupMouseSubscriptions(action: action)
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
