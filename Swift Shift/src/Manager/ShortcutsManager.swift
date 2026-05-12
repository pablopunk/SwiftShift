import ShortcutRecorder
import CGEventSupervisor
import AppKit

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

extension NSEvent.ModifierFlags {
  static let swiftShiftShortcutMask: NSEvent.ModifierFlags = [.command, .option, .shift, .control, .function]

  var swiftShiftShortcutFlags: NSEvent.ModifierFlags {
    intersection(.swiftShiftShortcutMask)
  }
}

struct KeyboardShortcut: Codable, Equatable {
  var keyCode: UInt16?
  private var modifierFlagsRawValue: UInt
  var characters: String?
  var charactersIgnoringModifiers: String?

  var modifierFlags: NSEvent.ModifierFlags {
    get { NSEvent.ModifierFlags(rawValue: modifierFlagsRawValue).swiftShiftShortcutFlags }
    set { modifierFlagsRawValue = newValue.swiftShiftShortcutFlags.rawValue }
  }

  var isModifierOnly: Bool {
    keyCode == nil
  }

  var usesFunctionModifier: Bool {
    modifierFlags.contains(.function)
  }

  var shortcutRecorderShortcut: Shortcut? {
    guard !usesFunctionModifier else { return nil }
    let rawKeyCode = keyCode ?? UInt16.max
    guard let shortcutKeyCode = KeyCode(rawValue: rawKeyCode) else { return nil }

    return Shortcut(
      code: shortcutKeyCode,
      modifierFlags: modifierFlags,
      characters: characters,
      charactersIgnoringModifiers: keyCode == nil ? nil : charactersIgnoringModifiers
    )
  }

  var displayString: String {
    let flags = modifierFlags
    var parts: [String] = []

    if flags.contains(.function) { parts.append("fn") }
    if flags.contains(.control) { parts.append("⌃") }
    if flags.contains(.option) { parts.append("⌥") }
    if flags.contains(.shift) { parts.append("⇧") }
    if flags.contains(.command) { parts.append("⌘") }

    if let keyCode = keyCode {
      parts.append(Self.displayString(forKeyCode: keyCode, charactersIgnoringModifiers: charactersIgnoringModifiers))
    }

    return parts.isEmpty ? "Record Shortcut" : parts.joined()
  }

  init(keyCode: UInt16?, modifierFlags: NSEvent.ModifierFlags, characters: String? = nil, charactersIgnoringModifiers: String? = nil) {
    self.keyCode = keyCode
    self.modifierFlagsRawValue = modifierFlags.swiftShiftShortcutFlags.rawValue
    self.characters = characters
    self.charactersIgnoringModifiers = charactersIgnoringModifiers
  }

  init(shortcut: Shortcut) {
    let legacyKeyCode = shortcut.keyCode.rawValue
    let isModifierOnly = shortcut.charactersIgnoringModifiers == nil || legacyKeyCode == UInt16.max
    self.init(
      keyCode: isModifierOnly ? nil : legacyKeyCode,
      modifierFlags: shortcut.modifierFlags,
      characters: shortcut.characters,
      charactersIgnoringModifiers: shortcut.charactersIgnoringModifiers
    )
  }

  static func canUseWithoutModifiers(keyCode: UInt16) -> Bool {
    functionKeyCodes.contains(keyCode)
  }

  private static let functionKeyCodes = Set<UInt16>([
    122, 120, 99, 118, 96, 97, 98, 100, 101, 109,
    103, 111, 105, 107, 113, 106, 64, 79, 80, 90
  ])

  private static func displayString(forKeyCode keyCode: UInt16, charactersIgnoringModifiers: String?) -> String {
    if let charactersIgnoringModifiers = charactersIgnoringModifiers, !charactersIgnoringModifiers.isEmpty {
      if charactersIgnoringModifiers == " " {
        return "Space"
      }
      return charactersIgnoringModifiers.uppercased()
    }

    switch keyCode {
    case 36: return "Return"
    case 48: return "Tab"
    case 49: return "Space"
    case 51: return "Delete"
    case 53: return "Esc"
    case 64: return "F17"
    case 79: return "F18"
    case 80: return "F19"
    case 90: return "F20"
    case 96: return "F5"
    case 97: return "F6"
    case 98: return "F7"
    case 99: return "F3"
    case 100: return "F8"
    case 101: return "F9"
    case 103: return "F11"
    case 105: return "F13"
    case 106: return "F16"
    case 107: return "F14"
    case 109: return "F10"
    case 111: return "F12"
    case 113: return "F15"
    case 118: return "F4"
    case 120: return "F2"
    case 122: return "F1"
    case 123: return "Left"
    case 124: return "Right"
    case 125: return "Down"
    case 126: return "Up"
    default: return "<\(keyCode)>"
    }
  }
}

struct UserShortcut {
  var type: ShortcutType
  var shortcut: Shortcut?
  var keyboardShortcut: KeyboardShortcut?
  var mouseButton: MouseButton

  init(type: ShortcutType, shortcut: Shortcut? = nil, keyboardShortcut: KeyboardShortcut? = nil, mouseButton: MouseButton) {
    self.type = type
    self.shortcut = shortcut
    self.keyboardShortcut = keyboardShortcut ?? shortcut.map { KeyboardShortcut(shortcut: $0) }
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
    guard let keyboardShortcut = userShortcut.keyboardShortcut else {
      delete(for: userShortcut.type)
      return
    }

    do {
      let data = try JSONEncoder().encode(keyboardShortcut)
      UserDefaults.standard.set(data, forKey: keyboardShortcutKey(for: userShortcut.type))
      UserDefaults.standard.set(userShortcut.mouseButton.rawValue, forKey: mouseButtonKey(for: userShortcut.type))

      if let shortcut = userShortcut.shortcut ?? keyboardShortcut.shortcutRecorderShortcut {
        let data = try NSKeyedArchiver.archivedData(withRootObject: shortcut, requiringSecureCoding: false)
        UserDefaults.standard.set(data, forKey: userShortcut.type.rawValue)
      } else {
        UserDefaults.standard.removeObject(forKey: userShortcut.type.rawValue)
      }
    } catch {
      print("Error: \(error)")
    }
    updateGlobalShortcuts()
  }

  func load(for type: ShortcutType) -> UserShortcut? {
    let mouseButton = MouseButton.parse(rawValue: UserDefaults.standard.string(forKey: mouseButtonKey(for: type)))

    if let data = UserDefaults.standard.data(forKey: keyboardShortcutKey(for: type)) {
      do {
        let keyboardShortcut = try JSONDecoder().decode(KeyboardShortcut.self, from: data)
        let shortcut = loadLegacyShortcut(for: type) ?? keyboardShortcut.shortcutRecorderShortcut
        return UserShortcut(type: type, shortcut: shortcut, keyboardShortcut: keyboardShortcut, mouseButton: mouseButton)
      } catch {
        print("Error decoding shortcut: \(error.localizedDescription)")
      }
    }

    if let shortcut = loadLegacyShortcut(for: type) {
      return UserShortcut(type: type, shortcut: shortcut, mouseButton: mouseButton)
    }

    return nil
  }

  func delete(for type: ShortcutType) {
    UserDefaults.standard.removeObject(forKey: keyboardShortcutKey(for: type))
    UserDefaults.standard.removeObject(forKey: type.rawValue)
    UserDefaults.standard.removeObject(forKey: mouseButtonKey(for: type))
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

  private func keyboardShortcutKey(for type: ShortcutType) -> String {
    "\(type.rawValue)_keyboardShortcut"
  }

  private func mouseButtonKey(for type: ShortcutType) -> String {
    "\(type.rawValue)_mouseButton"
  }

  private func loadLegacyShortcut(for type: ShortcutType) -> Shortcut? {
    guard let data = UserDefaults.standard.data(forKey: type.rawValue) else { return nil }
    do {
      return try NSKeyedUnarchiver.unarchivedObject(ofClass: Shortcut.self, from: data)
    } catch {
      print("Error unarchiving data: \(error.localizedDescription)")
      return nil
    }
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

      let eventFlags = event.modifierFlags.swiftShiftShortcutFlags
      let shortcutFlags = shortcut.modifierFlags.swiftShiftShortcutFlags
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

  private func addEventMonitors(mouseAction: MouseAction, for userShortcut: UserShortcut) {
    guard userShortcut.keyboardShortcut != nil else { return }

    let eventHandler: (NSEvent) -> Void = { [weak self] event in
      self?.handleShortcutEvent(event, mouseAction: mouseAction, for: userShortcut)
    }

    if let monitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged, .keyDown, .keyUp], handler: eventHandler) {
      globalMonitors.append(monitor)
    }

    if let monitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown, .keyUp], handler: { event in
      eventHandler(event)
      return event
    }) {
      globalMonitors.append(monitor)
    }
  }

  private func handleShortcutEvent(_ event: NSEvent, mouseAction: MouseAction, for userShortcut: UserShortcut) {
    guard let keyboardShortcut = userShortcut.keyboardShortcut else { return }

    let shortcutType = userShortcut.type
    let isActive = activeShortcuts[shortcutType] ?? false

    switch event.type {
    case .flagsChanged:
      if keyboardShortcut.isModifierOnly {
        let isMatching = event.modifierFlags.swiftShiftShortcutFlags == keyboardShortcut.modifierFlags
        if isMatching && !isActive {
          startTracking(userShortcut, mouseAction)
          activeShortcuts[shortcutType] = true
        } else if !isMatching && isActive {
          stopTracking(userShortcut, mouseAction)
        }
      } else if isActive && event.modifierFlags.swiftShiftShortcutFlags != keyboardShortcut.modifierFlags {
        stopTracking(userShortcut, mouseAction)
      }
    case .keyDown:
      guard !event.isARepeat else { return }

      if keyboardShortcut.isModifierOnly {
        if isActive {
          stopTracking(userShortcut, mouseAction)
        }
      } else if matches(event, keyboardShortcut) {
        if !isActive {
          activeShortcuts[shortcutType] = true
          startTracking(userShortcut, mouseAction)
        }
      } else if isActive {
        stopTracking(userShortcut, mouseAction)
      }
    case .keyUp:
      if keyboardShortcut.isModifierOnly {
        if isActive {
          stopTracking(userShortcut, mouseAction)
        }
      } else if event.keyCode == keyboardShortcut.keyCode && isActive {
        stopTracking(userShortcut, mouseAction)
      }
    default:
      break
    }
  }

  private func matches(_ event: NSEvent, _ shortcut: KeyboardShortcut) -> Bool {
    guard let keyCode = shortcut.keyCode else { return false }
    return event.keyCode == keyCode && event.modifierFlags.swiftShiftShortcutFlags == shortcut.modifierFlags
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
      if let userShortcut = load(for: type), let keyboardShortcut = userShortcut.keyboardShortcut {
        let mouseAction = type == .move ? MouseAction.move : MouseAction.resize

        if keyboardShortcut.usesFunctionModifier || userShortcut.shortcut == nil {
          addEventMonitors(mouseAction: mouseAction, for: userShortcut)
        } else if let shortcut = userShortcut.shortcut {
          let isModifierOnlyShortcut = keyboardShortcut.isModifierOnly || shortcut.charactersIgnoringModifiers == nil

          if isModifierOnlyShortcut {
            addGlobalMonitors(mouseAction: mouseAction, for: userShortcut)
          } else {
            addActions(mouseAction: mouseAction, for: userShortcut)
          }
        } else {
          addEventMonitors(mouseAction: mouseAction, for: userShortcut)
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
