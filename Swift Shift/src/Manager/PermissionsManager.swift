import Cocoa

enum Preference {
  case accessibility
  case inputMonitoring
}

class PermissionsManager {
  static func hasAccessibilityPermission() -> Bool {
    let checkOptionPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let options = [checkOptionPrompt: false]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
  }
  
  static func openPreferences(at type: Preference) {
    switch type {
    case .accessibility:
      if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
        NSWorkspace.shared.open(url)
      }
    case .inputMonitoring:
      if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
        NSWorkspace.shared.open(url)
      }
    }
  }
}
