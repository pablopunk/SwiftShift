import Cocoa

enum Preference {
  case accessibility
  case inputMonitoring
}

class PermissionsManager {
  //    static var eventMonitor: Any?
  //    
  //    static func setupFakeMonitoring() {
  //        let eventMask = NSEvent.EventTypeMask.keyDown
  //        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask, handler: { event in
  //            // Handle the global key press event
  //            print("Global key press detected: \(event.keyCode)")
  //        })
  //    }
  //    
  //    static func hasInputMonitoringPermission() -> Bool {
  //        setupFakeMonitoring()
  //        
  //        if let _ = eventMonitor {
  //            // Successfully created an event monitor
  //            // Remove the event monitor as it's no longer needed for the check
  //            if let monitor = eventMonitor {
  //                NSEvent.removeMonitor(monitor)
  //                eventMonitor = nil
  //            }
  //            print("hasInputMonitoringPermission true")
  //            return true
  //        } else {
  //            // Failed to create an event monitor, likely due to lack of permissions
  //            print("hasInputMonitoringPermission false")
  //            return false
  //        }
  //    }
  
  static func hasAccessibilityPermission() -> Bool {
    // Check if the app has accessibility permissions
    // Note: This is a simplified check, and more robust methods may be needed
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
