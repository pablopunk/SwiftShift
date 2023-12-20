import Cocoa

class PermissionsManager {
    static func hasAccessibilityPermission() -> Bool {
        // Check if the app has accessibility permissions
        // Note: This is a simplified check, and more robust methods may be needed
        let checkOptionPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [checkOptionPrompt: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
